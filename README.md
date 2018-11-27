This application is not to be run as a service. This application uses a set of commands and a Redis DB to help compare the difference of two large data sets.

The data sets can be two directories on the same machine but this application was intended to work with datasets from many different sources (i.e. web scrapes vs downloads)

Often times one is given a web end point for downloads. One must then correlate the files on the remote server against what is already on disk. There are better ways to do such a thing such as `scp` or `rsync`. However, these services are not always available to us.

As such, these tools fill the gap in information we need to insure we have exact copies of our data.

## A test example.
See the `test/README.md` file for some quick live testing.

## A practical example.

There is a group known as IHG. IHG will produce many and large files. Every so often IHG will add new files and remove old files. It is our job to download and sync all files from IHG before they are removed. The only access to these files we have are via HTTP (Apache). We use `wget` to download any files that are presently on the server.

However, how do we know which files are new? How do we know how much space these files will end up taking? How many files are there or were there?

### Scanning our sources.

We end up web scraping the IHG server.
```
$ bin/ihg_fongl_scrape.sh [user_name] [password] [output_file.log]
```

We then convert this scrape into a csv.
```
$ bin/ihg_fongl_clean.sh [input_file] > [remote_scan.csv]
```

If we have files already downloaded from previous steps we want to scan locally.
```
$ bin/metis_scan.sh [directory] > [local_scan.csv]
```

These files can be hundreds of megabytes in size with hundreds of thousands of rows. If we were to just compare the lines (and thus file names and sizes and hashes) in a nested loop we could waste weeks of computation time.

To clear this hurdle we use the Redis DB. It is an in-memory key/value data store.
This drastically speeds up our comparison of files kept locally vs files still on the remote server.

### Updating and loading scans.

The Redis server has sixteen banks to store data indexed from 0 to 15. We load our scans into individual database "banks" and then compare the data that way.

Let us load some data into Redis.
```
$ bin/metis_utils update [redis_db_index] [scan_file.csv]
```
ex:
```
$ bin/metis_utils update 2 [remote_scan.csv]
$ bin/metis_utils update 3 [local_scan.csv]
```

The numbers `2` and `3`, for the `redis_db_index`, are arbitrary and are only for example purposes. You can use any of the sixteen db "banks" from 0 to 15.

As we complete more scans we can layer over our previous `updates` and get reports for when and where something was added (reports are output at the end of an update).

ex:
```
$ bin/metis_utils update 2 [remote_scan_oct_30.csv]
$ bin/metis_utils update 3 [local_scan_oct_12.csv]``
```

### Comparing and report generation.

From here we can get quick statistics about our data set (how many files, hashes, sizes)

```
$ bin/metis_utils status [redis_db_index]
```

Lastly, the main reason we are using this process is so we may compare the files from two sources with some efficiency.

```
$ bin/metis_utils diff [redis_db_index_A] [redis_db_index_B] [diff_output.csv]
```

### Data integrity.

It is very important that our data has md5 hashes associated with in. In the local scanning step above an md5 hash will be generated on the scan. If our partners on the remote end have created md5 hashes we can load those as well. The comparison of the hashes will happen in the previous "difference" step if the hashes are already present.

Some times the remote hashes are in an `md5checksum.txt` file. We need to load these hashes into the Redis DB that contains the remote file data.

Find the `md5checksum.txt` files that were downloaded locally.
```
$ find [download_dir] -name md5checksum.txt
```

For each file you find use the directory part and convert into scan files.
```
$ bin/metis_utis process_checksum_files [directory] [output_scan.csv]
```

You can now use the `bin/metis_utils update` command to update the appropriate Redis DB with the md5 checksums/hashes.
