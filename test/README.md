The folders and data contained here are dummy data to run tests on.
Below are a set of commands to test out the utilities (to be run from the app root directory):

### Scan a directory
Won't work on large data sets due to ruby memory restrictions. Use `bin/metis_scan.sh` instead.
`$ bin/metis_utils scan ./test/files ./test/scans/file_scan.04.csv`

### Update a set of data in Redis DB
`$ bin/metis_utils update 4 ./test/scans/file_scan.01.csv "test/files/"`
`$ bin/metis_utils update 4 ./test/scans/file_scan.02.csv "test/files/"`
`$ bin/metis_utils update 5 ./test/scans/file_scan.01.csv "test/files/"`
`$ bin/metis_utils update 5 ./test/scans/file_scan.02.csv "test/files/"`
`$ bin/metis_utils update 5 ./test/scans/file_scan.03.csv "test/files/"`

### Get the status of a data set in the Redis DB
`$ bin/metis_utils status 4`

### Generate a csv of already computed hashes.
To be used with/on/for md5checksum.txt files.
`$ bin/metis_utils process_checksum_files ./test/files/ ./test/test_hashes.csv`

### Update a set of data with computed hashes.
To be used with/on/for md5checksum.txt files.
`$ bin/metis_utils update 5 ./test/test_hashes.csv`

### Check the difference of two scans in the Redis DB.
`bin/metis_utils diff 4 5 ./test/difference.csv`
