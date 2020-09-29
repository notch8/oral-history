FROM solr:7.7

ENV SOLR_HOME=/solr_home \
    SOLR_CONFIG_DIR=/solr_conf

USER root
RUN mkdir $SOLR_CONFIG_DIR \
    && chown -R solr:solr $SOLR_CONFIG_DIR

RUN mkdir -p $SOLR_HOME && chown -R solr:solr $SOLR_HOME

USER solr
ADD conf $SOLR_CONFIG_DIR/blacklight_config

COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]
