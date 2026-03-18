# -----------------------------
# Base image with JDK (no manual Java install needed)
# -----------------------------
FROM openjdk:21-jdk-alpine

# -----------------------------
# Arguments / environment
# -----------------------------
ARG JMETER_VERSION="5.6.3"
ENV JMETER_HOME=/opt/apache-jmeter-${JMETER_VERSION}
ENV JMETER_BIN=${JMETER_HOME}/bin
ENV JMETER_DOWNLOAD_URL=https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz

ARG TZ="Europe/Amsterdam"
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk
ENV PATH=$PATH:$JMETER_BIN

# -----------------------------
# Install required tools
# -----------------------------
RUN apk update && apk add --no-cache ca-certificates tzdata curl unzip bash nss \
    && cp /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && update-ca-certificates \
    && rm -rf /var/cache/apk/* \
    && mkdir -p /tmp/dependencies /opt

# -----------------------------
# Download and extract JMeter
# -----------------------------
RUN curl -L --silent ${JMETER_DOWNLOAD_URL} -o /tmp/dependencies/apache-jmeter-${JMETER_VERSION}.tgz \
    && tar -xzf /tmp/dependencies/apache-jmeter-${JMETER_VERSION}.tgz -C /opt \
    && rm -rf /tmp/dependencies

WORKDIR ${JMETER_HOME}

# -----------------------------
# Copy plugin lists and entrypoint
# -----------------------------
COPY entrypoint.sh /
COPY plugins.txt /tmp/plugins.txt
COPY custom-plugins.txt /tmp/custom-plugins.txt

# -----------------------------
# Install Plugin Manager
# -----------------------------
RUN curl -L https://jmeter-plugins.org/get/ \
    -o ${JMETER_HOME}/lib/ext/jmeter-plugins-manager.jar \
    && java -cp ${JMETER_HOME}/lib/ext/jmeter-plugins-manager.jar \
       org.jmeterplugins.repository.PluginManagerCMDInstaller

# -----------------------------
# Install CMDRunner
# -----------------------------
RUN mkdir -p ${JMETER_HOME}/lib/cmdrunner \
    && curl -L https://repo1.maven.org/maven2/kg/apc/cmdrunner/2.3/cmdrunner-2.3.jar \
       -o ${JMETER_HOME}/lib/cmdrunner/CMDRunner-2.3.jar

# -----------------------------
# Install standard plugins
# -----------------------------
RUN JMETER_PLUGINS=$(paste -sd, /tmp/plugins.txt) \
    && java -jar ${JMETER_HOME}/lib/cmdrunner/CMDRunner-2.3.jar \
       --tool org.jmeterplugins.repository.PluginManagerCMD install $JMETER_PLUGINS

# -----------------------------
# Download custom plugins
# -----------------------------
RUN while read url; do \
        curl -L $url -o ${JMETER_HOME}/lib/ext/$(basename $url); \
    done < /tmp/custom-plugins.txt

# -----------------------------
# Entrypoint
# -----------------------------
ENTRYPOINT ["/entrypoint.sh"]
