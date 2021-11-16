#
# download swarm jar
#
FROM alpine:3 as downloader

ARG JSWARM_VERSION=3.15
ARG JSWARM_JAR_NAME=swarm-client-${JSWARM_VERSION}.jar
ARG JSWARM_URL=https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/${JSWARM_VERSION}/${JSWARM_JAR_NAME}

ARG JMXEX_VERSION=0.11.0
ARG JMXEX_JAR_NAME=jmx_prometheus_javaagent-${JMXEX_VERSION}.jar
ARG JMXEX_URL=https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/${JMXEX_VERSION}/${JMXEX_JAR_NAME}

RUN apk add --no-cache --upgrade curl

RUN curl -sSLo /${JSWARM_JAR_NAME} ${JSWARM_URL}
RUN curl -sSLo /${JMXEX_JAR_NAME} ${JMXEX_URL}

#
# pkg base
#
FROM alpine:3 as pkg_base

RUN apk add --no-cache --upgrade openjdk8 bash git docker

#
# construct swarm agent runtime
#
FROM pkg_base

ARG JSWARM_VERSION=3.15
ARG JSWARM_JAR_NAME=swarm-client-${JSWARM_VERSION}.jar
ARG JSWARM_JAR_DIR=/usr/share/jenkins
ARG JSWARM_JAR=${JSWARM_JAR_DIR}/${JSWARM_JAR_NAME}
ARG JSWARM_FSROOT=/j

ARG JSWARM_HOME=/home/jswarm
ARG JSWARM_USER=jswarm
ARG JSWARM_UID=888
ARG JSWARM_GROUP=${JSWARM_USER}
ARG JSWARM_GID=${JSWARM_UID}

ARG JMXEX_VERSION=0.11.0
ARG JMXEX_JAR_NAME=jmx_prometheus_javaagent-${JMXEX_VERSION}.jar
ARG JMXEX_JAR=${JSWARM_JAR_DIR}/${JMXEX_JAR_NAME}
ARG JMXEX_YAML_NAME=jmx_exporter.yaml
ARG JMXEX_YAML=${JSWARM_JAR_DIR}/${JMXEX_YAML_NAME}
ARG JMXEX_HOST=localhost
ARG JMXEX_PORT=8080

ENV JAVA=/usr/bin/java
ENV JSWARM_JAR=${JSWARM_JAR}
ENV JSWARM_FSROOT=${JSWARM_FSROOT}
ENV JSWARM_RUN=jenkins-swarm-client-run

# install swarm jar
RUN mkdir -p ${JSWARM_JAR_DIR}
RUN chmod 755 ${JSWARM_JAR_DIR}
COPY --from=downloader /${JSWARM_JAR_NAME} ${JSWARM_JAR}
RUN chmod 755 ${JSWARM_JAR}

# install jmx exporter jar
COPY --from=downloader /${JMXEX_JAR_NAME} ${JMXEX_JAR}
RUN chmod 755 ${JMXEX_JAR}

# install jmx exporter config
COPY ${JSWARM_RUN} /usr/local/bin/${JSWARM_RUN}
COPY ${JMXEX_YAML_NAME} ${JMXEX_YAML}

RUN addgroup -S -g ${JSWARM_GID} ${JSWARM_GROUP}
RUN adduser -S -u ${JSWARM_UID} -G ${JSWARM_GROUP} -h ${JSWARM_HOME} -s /bin/bash -D ${JSWARM_USER}

RUN mkdir -p ${JSWARM_FSROOT} \
    && chmod 6700 ${JSWARM_FSROOT} \
    && chown ${JSWARM_USER}:${JSWARM_USER} ${JSWARM_FSROOT}
VOLUME $JSWARM_FSROOT

USER $JSWARM_USER

ENV JAVA_ARGS=-javaagent:${JMXEX_JAR}=${JMXEX_HOST}:${JMXEX_PORT}:${JMXEX_YAML}
#EXPOSE ${JMXEX_PORT}

ENTRYPOINT ["bash", "-c", "/usr/local/bin/${JSWARM_RUN}"]
