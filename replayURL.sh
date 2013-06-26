#!/bin/sh
chain1="-A Mozilla -x pxp0:12345 -U user:pass"
chain1desc="pxp0"
chain2="-A Mozilla -x pxp1:12345"
chain2desc="pxp1"

echo "Method;URL;$chain1desc : Totaltime (s);$chain1desc : HTTP Code;$chain2desc : Totaltime (s);$chain2desc : HTTP Code" > $1.csv

while read line ; do
  method=`echo $line |cut -d " " -f 1`
	echo "La mehode est $method"
	case "$method" in
        "POST")
            curloptions="-w %{time_total};%{http_code} -d \"test\" http://" 
            ;;
         
        "GET")
            curloptions="-w %{time_total};%{http_code} http://" 
            ;;
         
        "CONNECT")
            curloptions="-w %{time_total};%{http_connect} https://" 
            ;;
			
        *)
            echo "Error in line $line"
			continue
	esac
	url=`echo $line |cut -d "/" -f 3-`
	curl_result1=`curl -m 10 -k -o /dev/null $chain1 $curloptions$url`
	curl_result2=`curl -m 10 -k -o /dev/null $chain2 $curloptions$url`
	echo "$method;$url;$curl_result1;$curl_result2" |sed 's/,/./g'>> $1.csv
done < $1
