#!/bin/bash

### Le format de log en entree doit etre : Tailleenbyte "Categorie/1 Categorie2" ACTION ...

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

#Ecriture de lentete du fichier CSV
echo "Categorie;Total Hits;OK;Denied;Total Bytes" > $1.csv
while read line ; do
	category=`echo "$line" | sed 's/\//\-/g'| sed 's/\ /\_/g'`
	category_simple=`echo "$line" | sed 's/\//\;/g'|cut -d ";" -f1`
	echo $category
	echo -n "$category : Counting hits............ "
	awk "/$category_simple/ {print}" $1 > tmp/"$category.txt"
	total=`wc -l tmp/"$category.txt" |cut -d " " -f 1`
	echo $total
	
	echo -n "$category : Counting succedeed....... "
	awk ' !/DENIED/ {print $1}' tmp/"$category.txt" > tmp/$category.ok
	passed=`wc -l tmp/"$category.ok" |cut -d " " -f 1`
	echo $passed
	
	echo -n "$category : Counting failed.......... "
	denied=`expr $total - $passed`
	echo $denied
	
	echo -n "$category : Counting size in bytes... "
	bytesum=`awk '{s+=$1} END {print s}' tmp/"$category.ok"`
	echo $bytesum

	echo "$line;$total;$passed;$denied;$bytesum" >> $1.csv
done < tmp/categories.txt
