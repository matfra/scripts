#!/bin/bash

if [ $# -eq 0 ]
  then
    echo '
Input must be a text file with the following format : 
URL Server_Size "Category" Action Cache_Action
http://www.eurosport.fr/refresh-pub.shtml?oaspos=Top 1006 "Sports/Recreation" OBSERVED TCP_REFRESH_MISS
...

Edit this script for more info
'
	exit
fi

export LC_ALL='C'


#Example to create this I used
#for authenticated users :
#for logfil in `ls *.gz` ; do echo $logfil && zcat $logfil |awk '$2!="-" {print $6,$10,$11,$12,$13}' >> Logs_auth.txt ; done

#for unauthenticated users :
#for logfil in `ls *.gz` ; do echo $logfil && zcat $logfil |awk '$2="-" {print $6,$10,$11,$12,$13}' >> Logs_non_auth.txt ; done

mkdir tmp

echo 'Abortion
Adult/Mature Content
Alcohol
Alternative Sexuality/Lifestyles
Alternative Spirituality/Belief
Art/Culture
Auctions
Audio/Video Clips
Blogs/Personal Pages
Brokerage/Trading
Business/Economy
Charitable Organizations
Chat/Instant Messaging
Child Pornography
Computers/Internet
Content Servers
Dynamic DNS Host
Education
Email
Entertainment
Extreme
Financial Services
For Kids
Gambling
Games
Government/Legal
Greeting Cards
Hacking
Health
Humor/Jokes
Illegal Drugs
Informational
Internet Telephony
Intimate Apparel/Swimsuit
Job Search/Careers
LGBT
Malicious Outbound Data/Botnets
Malicious Sources
Media Sharing
Military
News/Media
Newsgroups/Forums
Non-viewable
Nudity
Online Meetings
Online Storage
Open/Mixed Content
Pay to Surf
Peer-to-Peer (P2P)
Personals/Dating
Phishing
Placeholders
Political/Activist Groups
Pornography
Potentially Unwanted Software
Proxy Avoidance
Radio/Audio Streams
Real Estate
Reference
Religion
Remote Access Tools
Restaurants/Dining/Food
Scam/Questionable/Illegal
Search Engines/Portals
Sex Education
Shopping
Social Networking
Society/Daily Living
Software Downloads
Spam
Sports/Recreation
Suspicious
TV/Video Streams
Tobacco
Translation
Travel
Vehicles
Violence/Hate/Racism
Weapons
Web Advertisements
Web Applications
Web Hosting' > tmp/categories.txt	

#Top categories
echo "Categorie;Total Hits;OK;Denied;Total Bytes" > $1_topcat.csv
while read line ; do
	category=`echo "$line" | sed 's/\//\-/g'| sed 's/\ /\_/g'`
	category_simple=`echo "$line" | sed 's/\//\;/g'|cut -d ";" -f1`
	echo $category
	echo -n "$category : Counting hits............ "
	awk "/$category_simple/ {print}" $1 > tmp/"$category.txt"
	total=`wc -l tmp/"$category.txt" |cut -d " " -f1`
	echo $total
	
	echo -n "$category : Counting succedeed....... "
	awk ' !/ DENIED/ {print $2}' tmp/"$category.txt" > tmp/$category.ok
	passed=`wc -l tmp/"$category.ok" |cut -d " " -f1`
	echo $passed
	
	echo -n "$category : Counting failed.......... "
	denied=`expr $total - $passed`
	echo $denied
	
	echo -n "$category : Counting size in bytes... "
	bytesum=`awk '{s+=$1} END {print s}' tmp/"$category.ok"`
	echo $bytesum

	echo "$line;$total;$passed;$denied;$bytesum" >> $1_topcat.csv
#Top sites
	cat tmp/"$category.txt" |cut -d "/" -f 3-4 |cut -d " " -f1 |sort |uniq -c |sort |tail -20 > tmp/$category.top20
	while read urlline ; do
		url_hit=`echo $urlline | cut -d " " -f1`
		url=`echo $urlline | cut -d " " -f2`
		echo "$line;$url_hit;$url" >> $1_topsites_per_cat.csv
	done < tmp/$category.top20
done < tmp/categories.txt
