#!/bin/sh

SHARED_DIR='/home/shared'

echo 'Waiting for sslyze-scan results to be delivered...'
while true;
do
  if [[ -r $SHARED_DIR/artifacts/sslyze_results/sslyze.csv ]]
  then
    echo 'sslyze-scan results found!'
    break
  fi
  sleep 5
done

# Process sslyze-scan results and import them to the database
echo 'Processing results...'
./csv2mongo.py

# Clean up
echo 'Archiving results...'
mkdir -p $SHARED_DIR/archive/
cd $SHARED_DIR
TODAY=$(date +'%Y-%m-%d')
mv artifacts artifacts_$TODAY
tar -czf $SHARED_DIR/archive/artifacts_$TODAY.tar.gz artifacts_$TODAY/

# Clean up
echo 'Cleaning up'
rm -rf artifacts_$TODAY
