# Dockerfile for powered ELK stack
# Elasticsearch, Logstash, Kibana, Filebeat 5.6.3
# Cerebro v0.7.1

# Build with:
# docker build -t <repo-user>/powered-elk .

# Run with:
# docker run -p 5601:5601 -p 9200:9200 -p 5044:5044 -it --name powered-elk <repo-user>/powered-elk

FROM phusion/baseimage
MAINTAINER Alejandro Gómez https://github.com/lexfaraday
ENV REFRESHED_AT 2017-11-02


###############################################################################
#                                INSTALLATION
###############################################################################

### install prerequisites (cURL, gosu, JDK)

ENV GOSU_VERSION 1.8

ARG DEBIAN_FRONTEND=noninteractive
RUN set -x \
 && apt-get update -qq \
 && apt-get install -qqy --no-install-recommends ca-certificates curl \
 && rm -rf /var/lib/apt/lists/* \
 && curl -L -o /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
 && curl -L -o /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
 && export GNUPGHOME="$(mktemp -d)" \
 && gpg --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
 && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
 && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
 && chmod +x /usr/local/bin/gosu \
 && gosu nobody true \
 && apt-get update -qq \
 && apt-get install -qqy openjdk-8-jdk \
 && apt-get clean \
 && set +x


ENV ELK_VERSION 5.6.3

### install Elasticsearch

ENV ES_VERSION ${ELK_VERSION}
ENV ES_HOME /opt/elasticsearch
ENV ES_PACKAGE elasticsearch-${ES_VERSION}.tar.gz
ENV ES_GID 991
ENV ES_UID 991

RUN mkdir -p ${ES_HOME} \
 && curl -O https://artifacts.elastic.co/downloads/elasticsearch/${ES_PACKAGE} \
 && tar xzf ${ES_PACKAGE} -C ${ES_HOME} --strip-components=1 \
 && rm -f ${ES_PACKAGE} \
 && groupadd -r elasticsearch -g ${ES_GID} \
 && useradd -r -s /usr/sbin/nologin -M -c "Elasticsearch service user" -u ${ES_UID} -g elasticsearch elasticsearch \
 && mkdir -p /var/log/elasticsearch /etc/elasticsearch /etc/elasticsearch/scripts /var/lib/elasticsearch \
 && chown -R elasticsearch:elasticsearch ${ES_HOME} /var/log/elasticsearch /var/lib/elasticsearch /etc/elasticsearch

ADD ./elasticsearch-init /etc/init.d/elasticsearch
RUN sed -i -e 's#^ES_HOME=$#ES_HOME='$ES_HOME'#' /etc/init.d/elasticsearch \
 && chmod +x /etc/init.d/elasticsearch


### install Logstash

ENV LOGSTASH_VERSION ${ELK_VERSION}
ENV LOGSTASH_HOME /opt/logstash
ENV LOGSTASH_PACKAGE logstash-${LOGSTASH_VERSION}.tar.gz
ENV LOGSTASH_GID 992
ENV LOGSTASH_UID 992

RUN mkdir ${LOGSTASH_HOME} \
 && curl -O https://artifacts.elastic.co/downloads/logstash/${LOGSTASH_PACKAGE} \
 && tar xzf ${LOGSTASH_PACKAGE} -C ${LOGSTASH_HOME} --strip-components=1 \
 && rm -f ${LOGSTASH_PACKAGE} \
 && groupadd -r logstash -g ${LOGSTASH_GID} \
 && useradd -r -s /usr/sbin/nologin -d ${LOGSTASH_HOME} -c "Logstash service user" -u ${LOGSTASH_UID} -g logstash logstash \
 && mkdir -p /var/log/logstash /etc/logstash/conf.d \
 && chown -R logstash:logstash ${LOGSTASH_HOME} /var/log/logstash /etc/logstash

ADD ./logstash-init /etc/init.d/logstash
RUN sed -i -e 's#^LS_HOME=$#LS_HOME='$LOGSTASH_HOME'#' /etc/init.d/logstash \
 && chmod +x /etc/init.d/logstash


### install Filebeat

ENV FILEBEAT_VERSION ${ELK_VERSION}
ENV FILEBEAT_HOME /usr/share/filebeat
ENV FILEBEAT_PACKAGE filebeat-${FILEBEAT_VERSION}-amd64.deb
ENV FILEBEAT_GID 993
ENV FILEBEAT_UID 993

RUN curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/${FILEBEAT_PACKAGE} \
 && dpkg -i ${FILEBEAT_PACKAGE} \
 && rm -f ${FILEBEAT_PACKAGE} \
 && groupadd -r filebeat -g ${FILEBEAT_GID} \
 && useradd -r -s /usr/sbin/nologin -M -c "Filebeat service user" -u ${FILEBEAT_UID} -g filebeat filebeat \
 && mkdir -p /var/log/filebeat /var/lib/filebeat /var/log/origin \
 && chown -R filebeat:filebeat ${FILEBEAT_HOME} /var/log/filebeat /var/lib/filebeat /var/log/origin /etc/filebeat

ADD ./filebeat-init /etc/init.d/filebeat
RUN sed -i -e 's#^FILEBEAT_HOME=$#FILEBEAT_HOME='$FILEBEAT_HOME'#' /etc/init.d/filebeat \
 && chmod +x /etc/init.d/filebeat

### install Kibana

ENV KIBANA_VERSION ${ELK_VERSION}
ENV KIBANA_HOME /opt/kibana
ENV KIBANA_PACKAGE kibana-${KIBANA_VERSION}-linux-x86_64.tar.gz
ENV KIBANA_GID 994
ENV KIBANA_UID 994

RUN mkdir ${KIBANA_HOME} \
 && curl -O https://artifacts.elastic.co/downloads/kibana/${KIBANA_PACKAGE} \
 && tar xzf ${KIBANA_PACKAGE} -C ${KIBANA_HOME} --strip-components=1 \
 && rm -f ${KIBANA_PACKAGE} \
 && groupadd -r kibana -g ${KIBANA_GID} \
 && useradd -r -s /usr/sbin/nologin -d ${KIBANA_HOME} -c "Kibana service user" -u ${KIBANA_UID} -g kibana kibana \
 && mkdir -p /var/log/kibana \
 && chown -R kibana:kibana ${KIBANA_HOME} /var/log/kibana

ADD ./kibana-init /etc/init.d/kibana
RUN sed -i -e 's#^KIBANA_HOME=$#KIBANA_HOME='$KIBANA_HOME'#' /etc/init.d/kibana \
 && chmod +x /etc/init.d/kibana


### install Cerebro v.0.7.1

ENV CEREBRO_VERSION 0.7.1
ENV CEREBRO_HOME /opt/cerebro
ENV CEREBRO_PACKAGE cerebro-${CEREBRO_VERSION}.tgz
ENV CEREBRO_GID 995
ENV CEREBRO_UID 995

RUN mkdir ${CEREBRO_HOME} \
 && curl -OL https://github.com/lmenezes/cerebro/releases/download/v0.7.1/${CEREBRO_PACKAGE} \
 && tar xzf ${CEREBRO_PACKAGE} -C ${CEREBRO_HOME} --strip-components=1 \
 && rm -f ${CEREBRO_PACKAGE} \
 && groupadd -r cerebro -g ${CEREBRO_GID} \
 && useradd -r -s /usr/sbin/nologin -M -c "Cerebro service user" -u ${CEREBRO_UID} -g cerebro cerebro \
 && mkdir -p /var/log/cerebro \
 && chown -R cerebro:cerebro ${CEREBRO_HOME} /var/log/cerebro

ADD ./cerebro-init /etc/init.d/cerebro
RUN sed -i -e 's#^CEREBRO_HOME=$#CEREBRO_HOME='$CEREBRO_HOME'#' /etc/init.d/cerebro \
 && chmod +x /etc/init.d/cerebro


###############################################################################
#                               CONFIGURATION
###############################################################################

### configure Elasticsearch

ADD ./elasticsearch.yml /etc/elasticsearch/elasticsearch.yml
ADD ./elasticsearch-log4j2.properties /etc/elasticsearch/log4j2.properties
ADD ./elasticsearch-jvm.options /etc/elasticsearch/jvm.options
ADD ./elasticsearch-default /etc/default/elasticsearch
RUN chmod -R +r /etc/elasticsearch


### configure Logstash

# certs/keys for Beats and Lumberjack input
RUN mkdir -p /etc/pki/tls/certs && mkdir /etc/pki/tls/private
ADD ./logstash-beats.crt /etc/pki/tls/certs/logstash-beats.crt
ADD ./logstash-beats.key /etc/pki/tls/private/logstash-beats.key

# filters
ADD ./02-beats-input.conf /etc/logstash/conf.d/02-beats-input.conf
ADD ./10-syslog.conf /etc/logstash/conf.d/10-syslog.conf
ADD ./11-nginx.conf /etc/logstash/conf.d/11-nginx.conf
ADD ./30-output.conf /etc/logstash/conf.d/30-output.conf

# patterns
ADD ./nginx.pattern ${LOGSTASH_HOME}/patterns/nginx
RUN chown -R logstash:logstash ${LOGSTASH_HOME}/patterns

# Fix permissions
RUN chmod -R +r /etc/logstash

### configure logrotate

ADD ./elasticsearch-logrotate /etc/logrotate.d/elasticsearch
ADD ./logstash-logrotate /etc/logrotate.d/logstash
ADD ./kibana-logrotate /etc/logrotate.d/kibana
RUN chmod 644 /etc/logrotate.d/elasticsearch \
 && chmod 644 /etc/logrotate.d/logstash \
 && chmod 644 /etc/logrotate.d/kibana

### configure Filebeat

ADD ./filebeat.yml /etc/filebeat/filebeat.yml
RUN chmod -R +r /etc/filebeat

### configure Cerebro

ADD ./cerebro-logback.xml /opt/cerebro/conf/logback.xml
ADD ./cerebro-application.conf /opt/cerebro/conf/application.conf
RUN chmod -R +r /opt/cerebro/conf

### configure Kibana

ADD ./kibana.yml ${KIBANA_HOME}/config/kibana.yml


###############################################################################
#                                   START
###############################################################################

ADD ./start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

EXPOSE 5601 9000 9200 9300 5044
VOLUME /var/lib/elasticsearch
# Volume for filebeat collector, put your logs here :)
VOLUME /var/log/origin
# Volume for logstash configuration

CMD [ "/usr/local/bin/start.sh" ]
