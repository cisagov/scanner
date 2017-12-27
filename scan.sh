#!/bin/bash
SHARED_DIR='/home/scanner/shared'

echo "Creating artifacts folder..."
mkdir -p $SHARED_DIR/artifacts/

# Run the https-scan scan
echo "Running domain-scan/sslyze scan"
cd $SHARED_DIR/artifacts/
/home/scanner/domain-scan/scan $SHARED_DIR/scanme.csv --scan=pshtt,trustymail,sslyze --lambda --debug --cache --workers=800

# Clean up files no longer needed
rm -rf $SHARED_DIR/artifacts/cache
