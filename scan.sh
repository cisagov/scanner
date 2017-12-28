#!/bin/bash
SHARED_DIR='/home/scanner/shared'

echo "Creating artifacts folder..."
mkdir -p $SHARED_DIR/artifacts/

echo "Waiting for gatherer"
while [ "$(redis-cli -h orchestrator_redis_1 get gathering_complete)" != "true" ]
do
    sleep 5
done
echo "Gatherer finished"

# No longer needed
redis-cli -h orchestrator_redis_1 del gathering_complete

# Run the scan
echo "Running domain-scan/sslyze scan"
cd $SHARED_DIR/artifacts/

/home/scanner/domain-scan/scan $SHARED_DIR/scanme.csv --scan=pshtt --lambda --debug --cache --workers=400
# Let redis know we're done
redis-cli -h orchestrator_redis_1 set pshtt_scanning_complete true

/home/scanner/domain-scan/scan $SHARED_DIR/scanme.csv --scan=trustymail --lambda --debug --cache --workers=400
# Let redis know we're done
redis-cli -h orchestrator_redis_1 set trustymail_scanning_complete true

/home/scanner/domain-scan/scan $SHARED_DIR/scanme.csv --scan=sslyze --lambda --debug --cache --workers=400
# Let redis know we're done
redis-cli -h orchestrator_redis_1 set sslyze_scanning_complete true

# Clean up files no longer needed
rm -rf $SHARED_DIR/artifacts/cache
