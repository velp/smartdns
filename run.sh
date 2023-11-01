#!/bin/bash

_PUBLIC_IP=$(curl ifconfig.co)

mkdir -p /var/log/smartdns

docker build --network host -t smartdns .
docker rm --force smartdns
docker run -d --restart always --name smartdns --privileged --dns 1.1.1.1 \
    -p $_PUBLIC_IP:80:80/tcp -p $_PUBLIC_IP:443:443/tcp \
    -p $_PUBLIC_IP:53:53/udp -v /var/log/smartdns:/var/log/smartdns \
    --mount type=bind,source="$(pwd)"/domains.lst,target=/opt/domains.lst,readonly \
    smartdns
