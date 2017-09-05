#!/bin/bash
#JVM_XMS
#JVM_XMX
#JVM_XSS

java_opts=""
if [ -n "$JVM_XMS" ]; then
    java_opts+="-Xmx"$JVM_XMS"k"
fi
if [ -n "$JVM_XMX" ]; then
    java_opts+="-Xmx"$JVM_XMX"k"
fi
if [ -n "$JVM_XSS" ]; then
    java_opts+="-Xmx"$JVM_XSS"k"
fi

echo #java_opts
if [ -n "$java_opts" ]; then
    exec "$1" $java_opts "$2"
else
    exec "$@"
fi


