#!/bin/bash

websites_file="websites.csv"

function curl_request {
	cd ..
	mkdir -p curl_logs/"$2"
	# curl -s
	curl -v "$1" > curl_logs/"$2"/"$2"_"$i".log 2>&1
	cd captures
	killall tcpdump
}

function curl_flood {
	for i in {1..10}; do 
		host=$(echo "$1" | tr -cd '[:print:]')
		tcpdump -i eth0 -nn -w "capture_$2_$i.pcap" & (sleep 5; curl_request "$host" "$hostClean")
		# "tcp and host $2"
	done
}

sudo rm -Rf captures
sudo rm -Rf curl_logs
mkdir -p captures
cd captures

while read host; do
	echo Input host: "$host"
	hostClean=$(echo "$host" | sed -e 's/[^/]*\/\/\([^@]*@\)\?\([^:/]*\).*/\2/')
	echo Cleaned host: "$hostClean"
	curl_flood "$host" "$hostClean"
done < "../$websites_file"

sleep 5

for i in *.pcap; do
    [ -f "$i" ] || break
    tshark -r "$i" -T fields -E header=y -E separator=, -E quote=d -E occurrence=f -e frame.time -e tcp.flags.ack -e frame.len -e ip.proto -e ip.src -e ip.dst -e ip.len -e tcp.srcport -e tcp.dstport -e tcp.len  > "${i%.*}".csv 2> /dev/null
done
