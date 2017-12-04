#!/bin/sh
name="$1"
days="$2"
output="$4"
pass="$3"

usage(){
  echo "usage:"
  echo "  $0 name days pass output"
}

if [ -z "$name" ] \
  || [ -z "$days" ] \
  || [ -z "$output" ]; then
    usage
    exit 1
fi


cd /etc/ocserv/certs/

if [ ! -f "$output-key.pem" ];then
	echo create user key ...
	certtool --generate-privkey --sec-param=high --outfile "$output-key.pem"
fi

if [ ! -f /etc/ocserv/certs/"$output-cert.pem" ];then
	echo create user cert ...
	cat << EOF > user.tmpl
	cn = "$name"
	unit = "cnroute"
  unit = "all"
	expiration_days = $days
	signing_key
	tls_www_client
EOF
	certtool --generate-certificate --load-privkey "$output-key.pem" --load-ca-certificate ca-cert.pem --load-ca-privkey ca-key.pem --template user.tmpl --outfile "$output-cert.pem"
fi

if [ ! -f "$output.p12" ];then
	echo create user p12 ...
  #openssl pkcs12 -export -inkey "$output-key.pem" -in "$output-cert.pem" -certfile ca-cert.pem -out "$output.p12" -password pass:"$pass"
  certtool --to-p12 --load-privkey "$output-key.pem" --pkcs-cipher 3des-pkcs12 --load-certificate "$output-cert.pem" --outfile "$output.p12" --outder --password="$pass" --p12-name="${name}'s vpn"
fi
