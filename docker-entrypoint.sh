#!/bin/sh

if [ -z "$CA_CN" ]; then
	CA_CN="Common CA"
fi

if [ -z "$CA_ORG" ]; then
	CA_ORG="Common Org"
fi

if [ -z "$CA_DAYS" ]; then
	CA_DAYS=9999
fi

if [ -z "$SRV_CN" ]; then
	SRV_CN="www.example.com"
fi

if [ -z "$SRV_ORG" ]; then
	SRV_ORG="Server Org"
fi

if [ -z "$SRV_DAYS" ]; then
	SRV_DAYS=9999
fi

mkdir -p /etc/ocserv/certs
[ ! -f /etc/ocserv/ocserv.conf ] && cp -R /root/ocserv/* /etc/ocserv

cd /etc/ocserv/certs

if [ ! -f ca-key.pem ];then
	echo create ca key ...
	certtool --generate-privkey --sec-param=high --outfile ca-key.pem
fi

if [ ! -f ca-cert.pem ];then
	echo create ca cert ...
	cat > ca.tmpl <<EOF
	 cn = "$CA_CN"
	 organization = "$CA_ORG"
	 serial = 1
	 expiration_days = $CA_DAYS
	 ca
	 signing_key
	 cert_signing_key
	 crl_signing_key
EOF
	 certtool --generate-self-signed --load-privkey ca-key.pem --template ca.tmpl --outfile ca-cert.pem
fi

if [ ! -f /etc/ocserv/certs/server-key.pem ];then
	echo create server key ...
	certtool --generate-privkey --sec-param=high --outfile server-key.pem
fi

if [ ! -f /etc/ocserv/certs/server-cert.pem ];then
	echo create server cert ...
	cat > server.tmpl <<EOF
	cn = "$SRV_CN"
	organization = "$SRV_ORG"
	expiration_days = $SRV_DAYS
	signing_key
	encryption_key
	tls_www_server
EOF
	certtool --generate-certificate --load-privkey server-key.pem --load-ca-certificate ca-cert.pem --load-ca-privkey ca-key.pem --template server.tmpl --outfile server-cert.pem
fi


if [ ! -f /etc/ocserv/certs/crl.pem ];then
	echo create crl ...
	cat << EOF >crl.tmpl
crl_next_update = 365
crl_number = 1
EOF
	certtool --generate-crl --load-ca-privkey ca-key.pem --load-ca-certificate ca-cert.pem --template crl.tmpl --outfile crl.pem
fi

# Open ipv4 ip forward
sysctl -w net.ipv4.ip_forward=1

# Enable NAT forwarding
iptables -t nat -A POSTROUTING -j MASQUERADE
iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

# Enable TUN device
if [ ! -e /dev/net/tun ]; then
	mkdir -p /dev/net
	mknod /dev/net/tun c 10 200
	chmod 600 /dev/net/tun
fi

# Run OpenConnect Server
exec "$@"
