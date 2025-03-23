FROM alpine

ARG JMETER_VERSION="5.6.3"
ENV JMETER_HOME /opt/apache-jmeter-${JMETER_VERSION}
ENV JMETER_BIN ${JMETER_HOME}/bin
ENV JMETER_DOWNLOAD_URL https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz

# Install Java 21 and other required packages
ARG TZ="Europe/Amsterdam"
RUN apk update \
    && apk upgrade \
    && apk add --no-cache ca-certificates tzdata curl unzip bash nss openjdk21-jre \
    && update-ca-certificates \
    && rm -rf /var/cache/apk/* \
    && mkdir -p /tmp/dependencies \
    && curl -L --silent ${JMETER_DOWNLOAD_URL} -o /tmp/dependencies/apache-jmeter-${JMETER_VERSION}.tgz \
    && mkdir -p /opt \
    && tar -xzf /tmp/dependencies/apache-jmeter-${JMETER_VERSION}.tgz -C /opt \
    && rm -rf /tmp/dependencies

# Set JAVA_HOME and update PATH
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk
ENV PATH=$PATH:$JMETER_BIN

COPY entrypoint.sh /

WORKDIR ${JMETER_HOME}

COPY plugins.txt /tmp/plugins.txt
COPY custom-plugins.txt /tmp/custom-plugins.txt

# Install Plugin Manager
RUN curl -L https://jmeter-plugins.org/get/ \
    -o /opt/apache-jmeter-${JMETER_VERSION}/lib/ext/jmeter-plugins-manager.jar
RUN java -cp /opt/apache-jmeter-${JMETER_VERSION}/lib/ext/jmeter-plugins-manager.jar org.jmeterplugins.repository.PluginManagerCMDInstaller

RUN curl -L https://repo1.maven.org/maven2/kg/apc/cmdrunner/2.3/cmdrunner-2.3.jar \
    -o /opt/apache-jmeter-${JMETER_VERSION}/lib/cmdrunner-2.3.jar

# Read plugins.txt, convert to comma-separated, install standard plugins
RUN JMETER_PLUGINS=$(paste -sd, /tmp/plugins.txt) \
    && /opt/apache-jmeter-${JMETER_VERSION}/bin/PluginsManagerCMD.sh install $JMETER_PLUGINS

# Download custom plugins
RUN while read url; do \
      curl -L $url -o /opt/apache-jmeter-${JMETER_VERSION}/lib/ext/$(basename $url); \
    done < /tmp/custom-plugins.txt

ENTRYPOINT ["/entrypoint.sh"]
