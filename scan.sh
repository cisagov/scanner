#!/bin/bash

SHARED_DIR='/home/scanner/shared'

echo "Creating artifacts folder..."
mkdir -p $SHARED_DIR/artifacts/

echo "Waiting for gatherer"
while [ "$(redis-cli -h redis get gathering_complete)" != "true" ]
do
    sleep 5
done
echo "Gatherer finished"

# No longer needed
redis-cli -h redis del gathering_complete

# Run the https-scan scan
echo "Running domain-scan scan"
cd $SHARED_DIR/artifacts/
/home/scanner/domain-scan/scan \
    $SHARED_DIR/artifacts/scanme_no_ocsp_crl.csv \
    --scan=pshtt --lambda --debug --meta --cache --workers=550
# domain-scan removes all existing CSV result files before starting a
# new scan, so we need to stash the pshtt results in a safe place
mv $SHARED_DIR/artifacts/results/pshtt.csv \
   $SHARED_DIR/artifacts/pshtt.csv

/home/scanner/domain-scan/scan \
    $SHARED_DIR/artifacts/scanme_include_ocsp_crl.csv \
    --scan=trustymail --lambda --debug --meta --cache --workers=550
# domain-scan removes all existing CSV result files before starting a
# new scan, so we need to stash the trustymail results in a safe place
mv $SHARED_DIR/artifacts/results/trustymail.csv \
   $SHARED_DIR/artifacts/trustymail.csv

/home/scanner/domain-scan/scan \
    $SHARED_DIR/artifacts/scanme_include_ocsp_crl.csv \
    --scan=sslyze --lambda --debug --meta --cache --workers=550

# Now put the pshtt and trustymail results back
mv $SHARED_DIR/artifacts/pshtt.csv \
   $SHARED_DIR/artifacts/trustymail.csv \
   $SHARED_DIR/artifacts/results/

# Let redis know we're done
redis-cli -h redis set scanning_complete true
