#!/bin/bash

set -x

_CONF_DIR="${CONF_DIR:-/etc/smartdns}"

_CLR_RED="\e[31m"
_CLR_YELLOW="\e[33m"
_CLR_GREEN="\e[32m"
_CLR_RESET="\e[0m"

_PUBLIC_IP="${PUBLIC_IP:-$(curl ifconfig.co)}"
_DOMAIN_LIST="${DOMAIN_LIST_FILE:-/opt/domains.lst}"

function print_info() {
    echo -e "$_CLR_GREEN[INFO] $1$_CLR_RESET"
}

function print_warn() {
    echo -e "$_CLR_YELLOW[WARN] $1$_CLR_RESET"
}

function print_error() {
    echo -e "$_CLR_RED[ERROR] $1$_CLR_RESET"
}

function die() {
    print_error $1
    exit 1
}

function _apply_iptables() {
    iptables -t nat -N REDSOCKS
    iptables -t nat -A REDSOCKS -d 0.0.0.0/8 -j RETURN
    iptables -t nat -A REDSOCKS -d 10.0.0.0/8 -j RETURN
    iptables -t nat -A REDSOCKS -d 100.64.0.0/10 -j RETURN
    iptables -t nat -A REDSOCKS -d 127.0.0.0/8 -j RETURN
    iptables -t nat -A REDSOCKS -d 169.254.0.0/16 -j RETURN
    iptables -t nat -A REDSOCKS -d 172.16.0.0/12 -j RETURN
    iptables -t nat -A REDSOCKS -d 192.168.0.0/16 -j RETURN
    iptables -t nat -A REDSOCKS -d 198.18.0.0/15 -j RETURN
    iptables -t nat -A REDSOCKS -d 224.0.0.0/4 -j RETURN
    iptables -t nat -A REDSOCKS -d 240.0.0.0/4 -j RETURN
    iptables -t nat -A REDSOCKS -p tcp -j REDIRECT --to-ports 4433
    iptables -A OUTPUT -p tcp -m owner --uid-owner 0 -j RETURN
    iptables -A OUTPUT -p tcp -m multiport --dports 80,443 -j REDSOCKS
}

function _run_daemons() {
    for domain in `grep -v -E "^#|^$" $_DOMAIN_LIST`; do
        echo "address=/$domain/$_PUBLIC_IP" >> $_CONF_DIR/dnsmasq.conf
    done

    danted -D -f $_CONF_DIR/danted.conf
    dnsmasq -C $_CONF_DIR/dnsmasq.conf
    redsocks -c $_CONF_DIR/redsocks.conf
    sniproxy -c $_CONF_DIR/sniproxy.conf
}

function _watcher() {
    while true; do
        for p in redsocks sniproxy dnsmasq; do
            pgrep -x $p > /dev/null || die "Process $p is not running! Exiting..."
        done

        sleep 10
    done
}

_run_daemons
_watcher

