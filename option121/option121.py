#!/usr/bin/python3
list = ['172.30.8.0/23/172.30.5.3', '172.30.12.0/22/172.30.5.3', '192.168.128.0/18/172.30.5.3', '172.30.80.20/32/172.30.5.3']

def removezeros(ipaddr):
	i = 3 # 4 bytes in IPv4 address
	strippedip = ''
	while i >= 0 :
		if ipaddr.split(sep=".")[i] != '0':
			break
		i -= 1
	j = 0
	while j <= i :
		strippedip += ipaddr.split(sep=".")[j] #Rewriting the shorter IP address
		if i != j :
			strippedip += '.' #Do not add separator . if it's the last byte
		j += 1
	return strippedip

def dec2hex(number):
		fullhex=hex(int(number))
		if int(number) < 16 :
			return ('0' + str(fullhex).split(sep="x")[1])
		return (fullhex.split(sep="x")[1])
	
def ipblock(netip, netmask, gw):
	concatblock = netmask + '.' + removezeros(netip) + '.' + gw
	finalblock = ''
	for byte in concatblock.split(sep="."):
		finalblock += dec2hex(byte)
		finalblock += ':'
	return (finalblock)

def option121(list):
	string = ''
	for route in list:
		netip = route.split(sep="/")[0]
		netmask = route.split(sep="/")[1]
		gw = route.split(sep="/")[2]
		string += ipblock(netip, netmask, gw)
	return (string.strip(':'))
	
print(option121(list))
