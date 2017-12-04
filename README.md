# docker-ocserv

docker-ocserv is an OpenConnect VPN Server boxed in a Docker image which is modified from [docker-ocserv](https://github.com/TommyLau/docker-ocserv).


## What is OpenConnect Server?

[OpenConnect server (ocserv)](http://www.infradead.org/ocserv/) is an SSL VPN server. It implements the OpenConnect SSL VPN protocol, and has also (currently experimental) compatibility with clients using the [AnyConnect SSL VPN](http://www.cisco.com/c/en/us/support/security/anyconnect-vpn-client/tsd-products-support-series-home.html) protocol.

## New function

I remove the route and all group, everyone connected the vpn will access China Mainland website directly and other connection will be protected by it.

I tried using certificate verification and group accounts using OU, but it does not work, so I will add the function back when I fix it.

It supports both certificate and password auth, there are 5 files which will be created if not exist.

1. /etc/ocserv/ocserv.conf it will import the default settings if the configuration does not exist !!!
2. /etc/ocserv/certs/ca-cert.pem ca certificate
3. /etc/ocserv/certs/ca-key.pem ca key
4. /etc/ocserv/certs/server-cert.pem server certificate
5. /etc/ocserv/certs/server-key.pem server key

Heavily suggests that you'd better volume the directory /etc/ocserv and link the files if you already have ( just like server and ca ). Someone who imported the user.p12 will not be asked for the password.

You can create the user certificate using

```bash
docker exec -ti ocserv create_ocserv_user.sh [name] [days] [password] [output name]
```
it will create the files in the directory /etc/ocserv/certs

## How to use this image

Get the docker image by running the following commands:

```bash
docker pull henry42/docker-ocserv
```

Start an ocserv instance:

```bash
docker run --name ocserv --privileged -p 443:443 -p 443:443/udp -v /etc/ocserv:/etc/ocserv -d henry42/docker-ocserv
```

### Environment Variables

All the variables to this image is optional, which means you don't have to type in any environment variables, and you can have a OpenConnect Server out of the box! However, if you like to config the ocserv the way you like it, here's what you wanna know.

`ROUTE`, `refresh` will refresh the cn route.

`CA_CN`, this is the common name used to generate the CA(Certificate Authority).

`CA_ORG`, this is the organization name used to generate the CA.

`CA_DAYS`, this is the expiration days used to generate the CA.

`SRV_CN`, this is the common name used to generate the server certification.

`SRV_ORG`, this is the organization name used to generate the server certification.

`SRV_DAYS`, this is the expiration days used to generate the server certification.

The default values of the above environment variables:

|   Variable   |     Default     |
|:------------:|:---------------:|
|  **CA_CN**   |   Common CA     |
|  **CA_ORG**  |   Common Org    |
| **CA_DAYS**  |       9999      |
|  **SRV_CN**  | www.example.com |
| **SRV_ORG**  |    Server Org   |
| **SRV_DAYS** |       9999      |

### Running examples

```bash
docker run --name ocserv --privileged -p 443:443 -p 443:443/udp -d henry42/docker-ocserv
```

Start an instance with server name `my.test.com`, `My Test` and `365` days

```bash
docker run --name ocserv --privileged -p 443:443 -p 443:443/udp -e SRV_CN=my.test.com -e SRV_ORG="My Test" -e SRV_DAYS=365 -d henry42/docker-ocserv
```

Start an instance with CA name `My CA`, `My Corp` and `3650` days

```bash
docker run --name ocserv --privileged -p 443:443 -p 443:443/udp -e CA_CN="My CA" -e CA_ORG="My Corp" -e CA_DAYS=3650 -d henry42/docker-ocserv
```

A totally customized instance with both CA and server certification

```bash
docker run --name ocserv --privileged -p 443:443 -p 443:443/udp -e CA_CN="My CA" -e CA_ORG="My Corp" -e CA_DAYS=3650 -e SRV_CN=my.test.com -e SRV_ORG="My Test" -e SRV_DAYS=365 -d henry42/docker-ocserv
```

Start an instance as above but without test user

```bash
docker run --name ocserv --privileged -p 443:443 -p 443:443/udp -e CA_CN="My CA" -e CA_ORG="My Corp" -e CA_DAYS=3650 -e SRV_CN=my.test.com -e SRV_ORG="My Test" -e SRV_DAYS=365 -v /some/path/to/ocpasswd:/etc/ocserv/ocpasswd -d henry42/docker-ocserv
```


### User operations

All the users opertaions happened while the container is running. If you used a different container name other than `ocserv`, then you have to change the container name accordingly.

#### Add user

If say, you want to create a user named `tommy`, type the following command

```bash
docker exec -ti ocserv ocpasswd -c /etc/ocserv/ocpasswd  tommy
Enter password:
Re-enter password:
```

When prompt for password, type the password twice, then you will have the user with the password you want.


#### Delete user

Delete user is similar to add user, just add another argument `-d` to the command line

```bash
docker exec -ti ocserv ocpasswd -c /etc/ocserv/ocpasswd -d test
```

#### Change password

Change password is exactly the same command as add user, please refer to the command mentioned above.
