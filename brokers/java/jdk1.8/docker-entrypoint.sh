#!/bin/bash
#JVM_XMS
#JVM_XMX
#JVM_XSS

java_opts=""
if [ -n "$JVM_XMS" ]; then
    if grep '^[[:digit:]]*$' <<< "$JVM_XMS";then
       if [ $JVM_XMS -gt 0 ]; then
           java_opts+="-Xmx"$JVM_XMS"k"
       fi
    fi
fi
if [ -n "$JVM_XMX" ]; then
    if grep '^[[:digit:]]*$' <<< "$JVM_XMX";then
       if [ $JVM_XMX -gt 0 ]; then
            java_opts+="-Xmx"$JVM_XMX"k"
       fi
   fi
fi
if [ -n "$JVM_XSS" ]; then
   if grep '^[[:digit:]]*$' <<< "$JVM_XSS";then
       if [ $JVM_XSS -gt 0 ]; then
            java_opts+="-Xmx"$JVM_XSS"k"
       fi
   fi
fi

#echo java_opts
if [ -n "$java_opts" ]; then
    if [ $1 == "java" ];then
        # 获取2~n个参数
        output=""
        for((i=2;i<=$#;i++)); do
            j=${!i}
            output="${output} $j "
        done
        echo ${output}
        exec `$1 $java_opts $output`
	else
        exec "$@"
	fi
else
    exec "$@"
fi




