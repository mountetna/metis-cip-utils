## How to scan the IHG data

Scanning the IHG data will involve a bash script and a ruby/rack applicaiton. Invoking the ruby/rack applicaiton is done with the `bin/ihg` command. Running the bare command will print out a list of sub commands which we will use to process and inspect the IHG scrape data.

Normally scanning and diffing such a large file would be computationally expensive and time consuming. If we did the scanning and diffing with only bash we are looking at weeks of time to complete our task. To overcome this we use the Redis in memory key/value database to speed our tasks along. See `Step 2.5` for more details.

### Step 1. web scrape the IHG server

Using the web scraping script, scrape the IHG server for files at the location `https://ihg-client.ucsf.edu/fongl/`.
`$ bin/fongl-ihg-scrape.sh > ./data/ihg_scrapes/01-fongl-ihg-scrape_[MONTH]_[DATE].log;`
ex:
`$ bin/fongl-ihg-scrape.sh > ./data/ihg_scrapes/01-fongl-ihg-scrape_oct_22.log;`


### Step 2. prune the web scrape

The web scrape has a whole bunch of extra data relating to the webserver. You don't need that data and it gets in the way. We want to transform the log file into a CSV file which has the size of the file, the date of the scan, and the path of the file with the file's name.

`$ bin/ihg ihg_prune ./data/ihg_scrapes/01-fongl-ihg-scrape_[MONTH]_[DATE].log ./data/ihg_cleans/02-fongl-ihg-clean_[MONTH]_[DATE].csv;`
ex:
`$ bin/ihg ihg_prune ./data/ihg_scrapes/01-fongl-ihg-scrape_oct_22.log ./data/ihg_cleans/02-fongl-ihg-clean_oct_22.csv;`

### Step 2.5 install and load the Redis DB

I will not get into the details of setting up the Redis DB here. However, you need to first run the following step ONCE before the next step.

Load an initial pruned scan into the Redis DB (This command will use DB index 1).

`$ bin/ihg ihg_load `
