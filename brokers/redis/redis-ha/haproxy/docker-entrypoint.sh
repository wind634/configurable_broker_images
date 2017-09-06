#!/bin/bash

sed -i "s/{{balance}}/${HAPROXY_BALANCE}/g" /usr/local/etc/haproxy/haproxy.cfg
sed -i "s/auth_key/${REDIS_AUTH_PASSWORD}/g" /usr/local/etc/haproxy/haproxy.cfg
sed -i "s/server master master:6379 check inter 1s/server ${APPNAME}_master ${APPNAME}_master:6379 check inter 1s/g" /usr/local/etc/haproxy/haproxy.cfg
sed -i "s/server slave slave:6379 check inter 1s/server ${APPNAME}_slave ${APPNAME}_slave:6379 check inter 1s/g" /usr/local/etc/haproxy/haproxy.cfg
sed -i "s/server slave1 slave1:6379 check inter 1s/server ${APPNAME}_slave1 ${APPNAME}_slave1:6379 check inter 1s/g" /usr/local/etc/haproxy/haproxy.cfg

HAPROXY_BALANCE

set -e

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- haproxy "$@"
fi

if [ "$1" = 'haproxy' ]; then
	# if the user wants "haproxy", let's use "haproxy-systemd-wrapper" instead so we can have proper reloadability implemented by upstream
	shift # "haproxy"
	set -- "$(which haproxy-systemd-wrapper)" -p /run/haproxy.pid "$@"
fi

exec "$@"