#!/bin/sh

JAVA=`which java`

if [ ! -x "$JAVA" ]; then
    echo "Could not find any executable java binary. Please install java in your PATH or set JAVA_HOME"
    exit 1
fi

if [ -z "$HORNETQ_JMX_HOST" ]; then
   HORNETQ_JMX_HOST=$(hostname -f)
fi

if [ -z "$JAVA_OPTS" ]; then
   JAVA_OPTS="-XX:+UseParallelGC \
              -XX:+AggressiveOpts \
              -XX:+UseFastAccessorMethods \
              -Xms512M -Xmx1024M \
              -Djava.naming.factory.initial=org.jnp.interfaces.NamingContextFactory \
              -Djava.naming.factory.url.pkgs=org.jboss.naming:org.jnp.interfaces \
              -Dorg.hornetq.logger-delegate-factory-class-name=org.hornetq.integration.logging.Log4jLogDelegateFactory \
              -Dhornetq.config.dir=/etc/hornetq \
              -Djava.library.path=/usr/lib64/hornetq"
fi

if [ -z "$JMX_OPTS" ]; then
   JMX_OPTS="-Djava.rmi.server.hostname=$HORNETQ_JMX_HOST \
             -Dcom.sun.management.jmxremote \
             -Dcom.sun.management.jmxremote=true \
             -Dcom.sun.management.jmxremote.port=5450 \
             -Dcom.sun.management.jmxremote.authenticate=false \
             -Dcom.sun.management.jmxremote.ssl=false"
fi

if [ -z "$HORNETQ_HOME" ]; then
    HORNETQ_HOME="."
fi

# make hornetq_HOME absolute
HORNETQ_HOME=`cd "$HORNETQ_HOME"; pwd`

HORNETQ_CLASSPATH="$HORNETQ_HOME/lib/*"

if [ -z "$HORNETQ_CONFDIR" ]; then
   HORNETQ_CONFDIR="conf"
fi

HORNETQ_CLASSPATH=$HORNETQ_CLASSPATH:$HORNETQ_CONFDIR
HORNETQ_LOG=log/hornetq.log

if [ -z "$HORNETQ_CLASSPATH" ]; then
    echo "You must set the HORNETQ_CLASSPATH var" >&2
    exit 1
fi

daemonized=`echo $* | grep -E -- '(^-d |-d$| -d |--daemonize$|--daemonize )'`
if [ -z "$daemonized" ] ; then
    exec "$JAVA" $JAVA_OPTS $JMX_OPTS -cp "$HORNETQ_CLASSPATH" \
          org.hornetq.integration.bootstrap.HornetQBootstrapServer hornetq-beans.xml
else
    exec "$JAVA" $JAVA_OPTS $JMX_OPTS -cp "$HORNETQ_CLASSPATH" \
          org.hornetq.integration.bootstrap.HornetQBootstrapServer hornetq-beans.xml &> $HORNETQ_LOG &
    retval=$?
    pid=$!
    [ $retval -eq 0 ] || exit $retval
    echo $pid > $PID_FILE
fi

exit $?
