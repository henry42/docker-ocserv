FROM python:3.6.3-alpine3.6

MAINTAINER Henry <hyliang8497@gmail.com>

ENV OC_VERSION=0.11.9

WORKDIR /root/

COPY chnroute_to_ocserv.sh .
COPY ocserv ocserv
COPY create_user.sh /usr/local/sbin/create_ocserv_user.sh
COPY docker-entrypoint.sh /entrypoint.sh

RUN buildDeps=" \
		curl \
		wget \
		g++ \
		gnutls-dev \
		gpgme \
		libev-dev \
		libnl3-dev \
		libseccomp-dev \
		linux-headers \
		linux-pam-dev \
		lz4-dev \
		make \
		readline-dev \
		tar \
		xz \
	"; \
	set -x \
	&& pip install netaddr \
	&& apk add --update --virtual .build-deps $buildDeps \
	&& curl -SL "ftp://ftp.infradead.org/pub/ocserv/ocserv-$OC_VERSION.tar.xz" -o ocserv.tar.xz \
	&& curl -SL "ftp://ftp.infradead.org/pub/ocserv/ocserv-$OC_VERSION.tar.xz.sig" -o ocserv.tar.xz.sig \
	&& gpg --keyserver pgp.mit.edu --recv-key 96865171 \
	&& gpg --verify ocserv.tar.xz.sig \
	&& mkdir -p /usr/src/ocserv \
	&& tar -xf ocserv.tar.xz -C /usr/src/ocserv --strip-components=1 \
	&& rm ocserv.tar.xz* \
	&& cd /usr/src/ocserv \
	&& ./configure \
	&& make \
	&& make install \
	&& cd / \
	&& rm -fr /usr/src/ocserv \
	&& runDeps="$( \
		scanelf --needed --nobanner /usr/local/sbin/ocserv \
			| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
			| xargs -r apk info --installed \
			| sort -u \
		)" \
	&& apk add --virtual .run-deps $runDeps gnutls-utils iptables \
	&& apk del .build-deps \
	&& rm -rf /var/cache/apk/*

# Setup config
#RUN sh /root/chnroute_to_ocserv.sh "/etc/ocserv/config-per-group/cnroute" \
#	&& cp "/etc/ocserv/config-per-group/cnroute" "/etc/ocserv/defaults/user.conf"

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 443

CMD ["ocserv", "-c", "/etc/ocserv/ocserv.conf", "-f"]
