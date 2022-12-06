#!/bin/bash

SHARED_DIR="${CISA_HOME}"/shared

echo Creating artifacts folder...
mkdir -p "${SHARED_DIR}"/artifacts/

echo Waiting for gatherer
while [ "$(redis-cli -h redis get gathering_complete)" != "true" ]; do
  sleep 5
done
echo Gatherer finished

# No longer needed
redis-cli -h orchestrator_redis_1 del gathering_complete

# Run the https-scan scan
echo Running domain-scan scan
cd "${SHARED_DIR}"/artifacts/ || exit
# We run the three scans separately because we want to reduce the
# concurrency for trustymail scans.  This is to avoid a situation
# where DNS queries are too high a rate (more than 1024
# packets/second) from the same ENI.  When this happens the DNS
# queries in excess of 1024 packets/second are dropped, and hence DNS
# requests time out.
#
# See this link for more information about this VPC DNS limitation:
# https://docs.aws.amazon.com/vpc/latest/userguide/vpc-dns.html#vpc-dns-limits
#
# See this link for an explanation as to why the VPC DNS limitation
# was not initially a concern:
# https://aws.amazon.com/blogs/compute/announcing-improved-vpc-networking-for-aws-lambda-functions/
"${CISA_HOME}"/domain-scan/scan "${SHARED_DIR}"/artifacts/scanme.csv \
  --scan=pshtt \
  --lambda \
  --lambda-retries=1 \
  --debug \
  --meta \
  --cache \
  --workers=40
# This file would get deleted when we rerun domain-scan/scan if it
# stayed where it is
mv "${SHARED_DIR}"/artifacts/results/pshtt.csv "${SHARED_DIR}"/artifacts
"${CISA_HOME}"/domain-scan/scan "${SHARED_DIR}"/artifacts/scanme.csv \
  --scan=trustymail \
  --lambda \
  --lambda-retries=1 \
  --debug \
  --meta \
  --cache \
  --workers=25 \
  --smtp-localhost=ec2-100-27-42-254.compute-1.amazonaws.com
# This file would get deleted when we rerun domain-scan/scan if it
# stayed where it is
mv "${SHARED_DIR}"/artifacts/results/trustymail.csv "${SHARED_DIR}"/artifacts
"${CISA_HOME}"/domain-scan/scan "${SHARED_DIR}"/artifacts/scanme.csv \
  --scan=sslyze \
  --lambda \
  --lambda-retries=1 \
  --debug \
  --meta \
  --cache \
  --workers=40
# Restore the files that we had temporarily copied to a safe place
#
# Note that we cannot wrap {pshtt,trustymail} in double quotes, since
# that would force the braces to be interpreted as literals.
mv "${SHARED_DIR}"/artifacts/{pshtt,trustymail}.csv "${SHARED_DIR}"/artifacts/results

# Let redis know we're done
redis-cli -h redis set scanning_complete true
