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

# Run the https-scan scan
echo "Running domain-scan scan"
cd $SHARED_DIR/artifacts/
/home/scanner/domain-scan/scan $SHARED_DIR/artifacts/scanme.csv --scan=pshtt,trustymail,sslyze --lambda --debug --meta --cache --workers=550

# Let redis know we're done
redis-cli -h orchestrator_redis_1 set scanning_complete true
