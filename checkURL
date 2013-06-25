#!/bin/bash

if [ ! ${1: -8} == ".urllist" ] ; then

  echo '
Input must be a test file with .urllist extension
List should be this : 
https://toto.com
http://toto.fr
'
	exit
fi

PROXYLIST="pxp0:8080
pxp1:3131"

#Ecriture de lentete du fichier CSV
echo "URL;Proxy;Totaltime (s);HTTP Code; HTTPS Code" > $1.csv
while read url ; do
	echo $category
	echo "URL : $url"
	for proxy in $PROXYLIST; do
		echo "Using proxy $proxy"
		result=`curl -m 10 -k -o /dev/null -w %{time_total}\;%{http_code}\;%{http_connect} -x $proxy $url`
		echo "$url;$proxy;$result" >> $1.csv
	done
done < $1
