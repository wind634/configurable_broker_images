#!/bin/bash

# HAPROXY_MAXCONN
# HAPROXY_CONNECT_TIMEOUT
# HAPROXY_SERVER_TIMEOUT
# HAPROXY_CLIENT_TIMEOUT
# HAPROXY_BALANCE


if grep '^[[:digit:]]*$' <<< "$HAPROXY_MAXCONN";then
     # 正整数
    if [ $HAPROXY_MAXCONN -ge 0 ]; then
       sed -i "s/{{maxconn}}/${HAPROXY_MAXCONN}/g" /usr/local/etc/haproxy/haproxy.cfg
    else
       sed -i "s/{{maxconn}}/20480/g" /usr/local/etc/haproxy/haproxy.cfg
    fi
fi


if grep '^[[:digit:]]*$' <<< "$HAPROXY_CONNECT_TIMEOUT";then
    # 正整数
    if [ $HAPROXY_CONNECT_TIMEOUT -ge 0 ]; then
        sed -i "s/{{conn_timeout}}/${HAPROXY_CONNECT_TIMEOUT}/g" /usr/local/etc/haproxy/haproxy.cfg
    else
        sed -i "s/{{conn_timeout}}/5000/g" /usr/local/etc/haproxy/haproxy.cfg
    fi
fi


if grep '^[[:digit:]]*$' <<< "$HAPROXY_SERVER_TIMEOUT";then
    # 正整数
    if [ $HAPROXY_SERVER_TIMEOUT -ge 0 ]; then
        sed -i "s/{{server_timeout}}/${HAPROXY_SERVER_TIMEOUT}/g" /usr/local/etc/haproxy/haproxy.cfg
    else
        sed -i "s/{{server_timeout}}/50000/g" /usr/local/etc/haproxy/haproxy.cfg
    fi
fi


if grep '^[[:digit:]]*$' <<< "$HAPROXY_CLIENT_TIMEOUT";then
    # 正整数
    if [ $HAPROXY_CLIENT_TIMEOUT -ge 0 ]; then
        sed -i "s/{{client_timeout}}/${HAPROXY_CLIENT_TIMEOUT}/g" /usr/local/etc/haproxy/haproxy.cfg
    else
        sed -i "s/{{client_timeout}}/50000/g" /usr/local/etc/haproxy/haproxy.cfg
    fi
fi

pass="F"
case "$HAPROXY_BALANCE" in
    "roundrobin")
        pass="T"
    ;;
    "static-rr")
        pass="T"
    ;;
    "leastconn")
        pass="T"
    ;;
    "source")
        pass="T"
    ;;
    "uri")
        pass="T"
    ;;
    "url_param")
        pass="T"
    ;;
    "hdr"*)
        pass="T"
    ;;
    "rdp-cookie"*)
        pass="T"
    ;;
    *)
        pass="F"
    ;;
esac
if [ "$pass" = "T" ];then
    sed -i "s/{{balance}}/${HAPROXY_BALANCE}/g" /usr/local/etc/haproxy/haproxy.cfg
else
    sed -i "s/{{balance}}/roundrobin/g" /usr/local/etc/haproxy/haproxy.cfg
fi


sed -i "s/auth_key/${REDIS_AUTH_PASSWORD}/g" /usr/local/etc/haproxy/haproxy.cfg

sed -i "s/server master master:6379 check inter 1s/server ${APPNAME}_master ${APPNAME}_master:6379 check inter 1s/g" /usr/local/etc/haproxy/haproxy.cfg
sed -i "s/server slave slave:6379 check inter 1s/server ${APPNAME}_slave ${APPNAME}_slave:6379 check inter 1s/g" /usr/local/etc/haproxy/haproxy.cfg
sed -i "s/server slave1 slave1:6379 check inter 1s/server ${APPNAME}_slave1 ${APPNAME}_slave1:6379 check inter 1s/g" /usr/local/etc/haproxy/haproxy.cfg

cat /usr/local/etc/haproxy/haproxy.cfg

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