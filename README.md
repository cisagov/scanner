# NCATS pshtt, trustymail, and sslyze Scanning #

This tool is intended to be run via `docker-compose`.  There are two
containers that will be started:
* `scan` - Performs the scanning
  * `scan.sh`: Does set-up, does the scans, and cleans up
  * `gather-domains.sh`: Grabs current federal and all other sources
    for domains to scan
* `save_to_db` - Saves the scanned info to the database
  * `save_to_db.sh`: Waits for scan results to appear, calls
    `csv2mongo.py`, then cleans up
  * `csv2mongo.py`: Reads scan result data files and creates records
    in the database

## Setup ##
Before attempting to run this project, you must create
`secrets/db.yml` with the following format:

```
version: '1'

database:
  name: sslyze-scan
  uri: mongodb://<DB_USERNAME>:<DB_PASSWORD>@<DB_HOST>:<DB_PORT>/sslyze-scan
```

## Execution ##

To begin execution, run the following command:
```bash
docker-compose up
```

All output will end up in a tarball in the `shared/archive` directory.
