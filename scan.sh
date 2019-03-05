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
redis-cli -h orchestrator_redis_1 del gathering_complete

# Run the https-scan scan
echo "Running domain-scan scan"
cd $SHARED_DIR/artifacts/
/home/scanner/domain-scan/scan $SHARED_DIR/artifacts/scanme.csv --scan=pshtt,trustymail,sslyze --lambda  --lambda-retries=1 --debug --meta --cache --workers=100

# Let redis know we're done
redis-cli -h redis set scanning_complete true
