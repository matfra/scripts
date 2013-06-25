#!/bin/sh

#Process a lot of logfiles, so you can have a ETA

for logfil in `ls *.gz` ; do echo $logfil && zcat $logfil |awk '{print $9,$13}' > result1.txt ; done
