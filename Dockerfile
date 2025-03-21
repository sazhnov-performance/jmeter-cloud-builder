
FROM justb4/jmeter:5.6.3

ARG JMETER_PLUGINS="jpgc-casutg,jpgc-dummy"
COPY custom-plugins.txt /tmp/custom-plugins.txt

# Install Plugin Manager and standard plugins
RUN curl -L https://jmeter-plugins.org/get/ \
    -o /opt/apache-jmeter/lib/ext/jmeter-plugins-manager.jar \
 && /opt/apache-jmeter/bin/PluginsManagerCMD.sh install $JMETER_PLUGINS

# Download custom plugins
RUN while read url; do \
      curl -L $url -o /opt/apache-jmeter/lib/ext/$(basename $url); \
done < /tmp/custom-plugins.txt

ENTRYPOINT ["/opt/apache-jmeter/bin/jmeter"]
