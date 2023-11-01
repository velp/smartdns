FROM ubuntu:22.04
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y bash net-tools iproute2 iptables \
                                         openssl curl lsof gawk git php sniproxy \
                                         dnsmasq redsocks dante-server && \
    apt-get clean autoclean && \
    apt-get autoremove --yes && \
    mkdir -p /var/log/smartdns /etc/smartdns

COPY entrypoint.sh /
COPY ./configs/* /etc/smartdns
COPY domains.lst /opt/domains.lst

RUN chmod +x /entrypoint.sh

EXPOSE 53/udp
EXPOSE 80
EXPOSE 443

ENTRYPOINT ["/entrypoint.sh"]
