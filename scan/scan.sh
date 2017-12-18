#!/bin/bash
SHARED_DIR='/home/shared'

echo "Creating artifacts folder..."
mkdir -p $SHARED_DIR/artifacts/

# Gather domains to get most recent files
echo "Gathering domains..."
cd scripts/
./gather-domains.sh

# Run the https-scan scan
echo "Running domain-scan/sslyze scan"
cd $SHARED_DIR/artifacts/
/home/scanner/domain-scan/scan scanme.csv --scan=sslyze --debug --workers=50

# Move results to an archive folder, and to the report generation
# folder
if [ -e "results" ] ; then
    mv results sslyze_results
fi

# Clean up files no longer needed
rm -rf $SHARED_DIR/artifacts/cache
