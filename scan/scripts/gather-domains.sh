#!/bin/bash
SHARED_DIR='/home/shared'

###
# Gather hostnames for the sslyze scan.  Also do any necessary
# scrubbing of the data.
###

# We need a copy of current-federal for some of the code that saves
# the results to the database, so we download a copy of just that.  We
# need the raw file, and domain-scan/gather modifies the fields in the
# CSV, so we'll use wget here.
#
# I should look into doing this download closer to where it is
# actually used.
wget -F \
     https://raw.githubusercontent.com/GSA/data/master/dotgov-domains/current-federal.csv \
     -O current-federal.csv
cp current-federal.csv $SHARED_DIR/artifacts/current-federal-original.csv

###
# Gather hostnames using GSA/data, analytics.usa.gov, censys, EOT, and
# any local additions.
#
# We need --include-parents here to get the second-level domains.
#
# Censys is no longer free as of 12/1/2017, so we do not have access.
# We are instead pulling an archived version of the data from GSA/data
# on GitHub.
###
/home/scanner/domain-scan/gather current_federal,analytics_usa_gov,censys_snapshot,eot_2012,eot_2016,include,cyhy \
                                 --suffix=.gov --ignore-www --include-parents \
                                 --parents=https://raw.githubusercontent.com/GSA/data/master/dotgov-domains/current-federal.csv \
                                 --current_federal=https://raw.githubusercontent.com/GSA/data/master/dotgov-domains/current-federal.csv \
                                 --analytics_usa_gov=https://analytics.usa.gov/data/live/sites.csv \
                                 --censys_snapshot=https://raw.githubusercontent.com/GSA/data/master/dotgov-websites/censys-federal-snapshot.csv \
                                 --eot_2012=$SHARED_DIR/include/eot-2012.csv \
                                 --eot_2016=$SHARED_DIR/include/eot-2016.csv \
                                 --include=$SHARED_DIR/include/include.txt \
                                 --cyhy=$SHARED_DIR/include/fed_cyhy_web_hostnames-all.txt
cp results/gathered.csv gathered.csv
cp gathered.csv $SHARED_DIR/artifacts/gathered.csv

# Remove extra columns
cut -d"," -f1 gathered.csv  > scanme.csv

# Remove characters that might break parsing
sed -i '/^ *$/d;/@/d;s/ //g;s/\"//g;s/'\''//g' scanme.csv

# Move the scanme to the artifacts folder
mv scanme.csv $SHARED_DIR/artifacts/scanme.csv

# Clean up files that are no longer needed
rm -rf include.csv ./cache/ ./results/
