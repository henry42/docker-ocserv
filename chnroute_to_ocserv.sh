#!/bin/bash

temp_dir=`mktemp -d`

cd "$temp_dir"

wget http://ftp.afrinic.net/pub/stats/afrinic/delegated-afrinic-extended-latest >/dev/null 2>&1
wget http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-extended-latest >/dev/null 2>&1
wget http://ftp.arin.net/pub/stats/arin/delegated-arin-extended-latest >/dev/null 2>&1
wget http://ftp.lacnic.net/pub/stats/lacnic/delegated-lacnic-extended-latest >/dev/null 2>&1
wget http://ftp.ripe.net/pub/stats/ripencc/delegated-ripencc-extended-latest >/dev/null 2>&1
cat delegated-afrinic-extended-latest delegated-apnic-extended-latest delegated-arin-extended-latest delegated-lacnic-extended-latest delegated-ripencc-extended-latest >> delegated-all-latest
cat delegated-all-latest | grep ipv4 | grep CN | awk -F\| '{ printf("%s/%d\n", $4, 32-log($5)/log(2)) }'  > chnroute.txt
rm delegated*

python3 <<EOF
# -*- coding: utf-8 -*-
import os,re,netaddr
from netaddr import *

lines = [line.rstrip('\n') for line in open('chnroute.txt')]

summary = netaddr.cidr_merge(sorted(lines))
chnroute_merged = open("chnroute_merged.txt", "w", encoding='utf-8')
chnroute_merged.write('\n'.join([ str(x) for x in summary ]))
chnroute_merged.close()

mergedlines = [line.rstrip('\n') for line in open('chnroute_merged.txt')]
mergedlines = [w.replace('/12','/11') for w in mergedlines]
mergedlines = [w.replace('/13','/11') for w in mergedlines]
mergedlines = [w.replace('/14','/11') for w in mergedlines]
mergedlines = [w.replace('/15','/11') for w in mergedlines]
mergedlines = [w.replace('/16','/11') for w in mergedlines]
mergedlines = [w.replace('/17','/11') for w in mergedlines]
mergedlines = [w.replace('/18','/11') for w in mergedlines]
mergedlines = [w.replace('/19','/11') for w in mergedlines]
mergedlines = [w.replace('/20','/11') for w in mergedlines]
mergedlines = [w.replace('/21','/11') for w in mergedlines]
mergedlines = [w.replace('/22','/11') for w in mergedlines]
mergedlines = [w.replace('/23','/11') for w in mergedlines]
mergedlines = [w.replace('/24','/11') for w in mergedlines]
mergedlines = [w.replace('/25','/11') for w in mergedlines]
mergedlines = [w.replace('/26','/11') for w in mergedlines]
mergedlines = [w.replace('/27','/11') for w in mergedlines]
mergedlines = [w.replace('/28','/11') for w in mergedlines]
mergedlines = [w.replace('/29','/11') for w in mergedlines]
mergedlines = [w.replace('/30','/11') for w in mergedlines]
mergedlines = [w.replace('/31','/11') for w in mergedlines]
mergedlines = [w.replace('/32','/11') for w in mergedlines]

summary = netaddr.cidr_merge(sorted(mergedlines))
s = IPSet(summary)
s.remove('0.0.0.0/8')
s.remove('10.0.0.0/8')
s.remove('100.64.0.0/10')
s.remove('127.0.0.0/8')
s.remove('169.254.0.0/16')
s.remove('172.16.0.0/12')
s.remove('192.0.0.0/24')
s.remove('192.0.2.0/24')
s.remove('192.88.99.0/24')
s.remove('192.168.0.0/16')
s.remove('198.18.0.0/15')
s.remove('198.51.100.0/24')
s.remove('203.0.113.0/24')
s.remove('224.0.0.0/4')
s.remove('240.0.0.0/4')
s.remove('255.255.255.255/32')
summary = netaddr.cidr_merge(sorted(s.iter_cidrs()))
norouteone = open("cn-no-route1.txt", "w", encoding='utf-8')
norouteone.write('\n'.join([ 'no-route = ' + str(x.ip) + '/' + str(x.netmask) for x in summary ]))
norouteone.close()

s = IPSet(summary)
s.add('0.0.0.0/8')
s.add('10.0.0.0/8')
s.add('100.64.0.0/10')
s.add('127.0.0.0/8')
s.add('169.254.0.0/16')
s.add('172.16.0.0/12')
s.add('192.0.0.0/24')
s.add('192.0.2.0/24')
s.add('192.88.99.0/24')
s.add('192.168.0.0/16')
s.add('198.18.0.0/15')
s.add('198.51.100.0/24')
s.add('203.0.113.0/24')
s.add('224.0.0.0/4')
s.add('240.0.0.0/4')
s.add('255.255.255.255/32')
summary = netaddr.cidr_merge(sorted(s.iter_cidrs()))
noroute = open("cn-no-route.txt", "w", encoding='utf-8')
noroute.write('\n'.join([ 'no-route = ' + str(x.ip) + '/' + str(x.netmask) for x in summary ]))
noroute.close()

open('cn-no-route2.txt', 'w').write(re.sub('no-route = 192.168.0.0/255.255.0.0', 'no-route = 192.168.0.0/255.255.255.0\nno-route = 192.168.1.0/255.255.255.0\nno-route = 192.168.2.0/255.255.254.0\nno-route = 192.168.4.0/255.255.252.0\nno-route = 192.168.8.0/255.255.248.0\nno-route = 192.168.16.0/255.255.240.0\nno-route = 192.168.32.0/255.255.224.0\nno-route = 192.168.64.0/255.255.192.0\nno-route = 192.168.128.0/255.255.128.0', open('cn-no-route.txt', "r").read()))
os.remove('cn-no-route.txt')
EOF

if [ -f "$1" ];then
    echo "About `cat cn-no-route2.txt | wc -l` rules ..."
    echo "Updaing $1 ..."
    sed -i '/^no-route = /d' "$1"
    cat cn-no-route2.txt >> "$1"
    echo "Updaing $1 Done!"
    echo "You'd better restart the ocserv."
else
    cat cn-no-route2.txt
fi

cd - > /dev/null && rm -rf "$temp_dir"
