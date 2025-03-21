
FROM alpine/jmeter:5.6.3

COPY plugins.txt /tmp/plugins.txt
COPY custom-plugins.txt /tmp/custom-plugins.txt

# Install Plugin Manager
RUN curl -L https://jmeter-plugins.org/get/ \
    -o /opt/apache-jmeter-5.6.3/lib/ext/jmeter-plugins-manager.jar
RUN java -cp /opt/apache-jmeter-5.6.3/lib/ext/jmeter-plugins-manager.jar org.jmeterplugins.repository.PluginManagerCMDInstaller

RUN ls -l /opt/apache-jmeter-5.6.3/bin/

RUN curl -L https://repo1.maven.org/maven2/kg/apc/cmdrunner/2.3/cmdrunner-2.3.jar \
    -o /opt/apache-jmeter-5.6.3/lib/cmdrunner-2.3.jar

# Read plugins.txt, convert to comma-separated, install standard plugins
RUN JMETER_PLUGINS=$(paste -sd, /tmp/plugins.txt) \
    && /opt/apache-jmeter-5.6.3/bin/PluginsManagerCMD.sh install $JMETER_PLUGINS

# Download custom plugins
RUN while read url; do \
      curl -L $url -o /opt/apache-jmeter-5.6.3/lib/ext/$(basename $url); \
    done < /tmp/custom-plugins.txt

ENTRYPOINT ["/entrypoint.sh"]
