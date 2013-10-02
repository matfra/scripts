#!/bin/sh

#Creating header
echo -n "Date" > $1.csv
while read ip ; do
	echo -n ",$ip" >> $1.csv
done < $1


while true ; do
	#New line
	echo "" >> $1.csv
	date=`date -u "+%d/%m/%Y %H:%M"`
	echo -n "$date" >> $1.csv
	echo $date
	
	while read ip ; do
		#New line
		ping=`ping -c1 -q $ip |grep "=" |cut -d "/" -f4`
		echo -n ",$ping" >> $1.csv
		echo "IP : $ip / $ping"
	done < $1
sleep 55

done
