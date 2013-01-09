Data and Code for Data Mashups in R
=========================

This repository contains working data and code to use [Data Mashups in R](http://shop.oreilly.com/product/0636920018438.do), including

- Code that works with Yahoo's BOSS Geo services
- Census files
- Shapefiles

##To use

#### Get Yahoo! API keys

Create a project in https://developer.apps.yahoo.com/projects

    Note: This is not a free service.

###Get this repository
```
git clone git@github.com:leipzig/datamashupsinr.git
cd datamashupsinr
```

Edit `dataMashups.R` and fill in the `consumer key` and `consumer secret` strings you received from Yahoo. The consumer key looks like:
`dj0yJmk9UXQ0T1F6TU5nbFU1JmJ9WVdrOWFIbzVWRTFUTXpnbWNHbzlPVFE0TnpZeU1UVTJNZy0tJnN9Y23uc3VtZXJzZWNyZXQmeD02YQ--`
Don't forget the dashes at the end.

###Start R and Run
==========
```
install.packages(c("XML","PBSmapping","maptools","ROAuth"))
source("dataMashups.R")
```