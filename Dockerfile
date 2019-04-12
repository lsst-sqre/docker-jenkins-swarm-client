#
# download swarm jar
#
FROM alpine:3.9 as downloader

ARG JSWARM_VERSION=3.14
ARG JSWARM_JAR_NAME=swarm-client-${JSWARM_VERSION}.jar
ARG DL_BASE_URL=https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client

RUN apk add --no-cache --upgrade curl

RUN curl -sSLo /${JSWARM_JAR_NAME} \
    ${DL_BASE_URL}/${JSWARM_VERSION}/${JSWARM_JAR_NAME}

#
# construct swarm agent runtime
#
FROM alpine:3.9

ARG JSWARM_VERSION=3.14
ARG JSWARM_JAR_NAME=swarm-client-${JSWARM_VERSION}.jar
ARG JSWARM_JAR_PATH=/usr/share/jenkins
ARG JSWARM_JAR=${JSWARM_JAR_PATH}/${JSWARM_JAR_NAME}
ARG HOME=/j
ARG USER=jenkins-swarm

ENV JSWARM_RUN=jenkins-swarm-client-run
ENV JAVA /usr/bin/java
ENV JSWARM_JAR=${JSWARM_JAR}

RUN apk add --no-cache --upgrade openjdk8 bash git

# install docker client
RUN apk add --no-cache --upgrade docker
RUN chmod u+s /usr/bin/docker

RUN mkdir -p ${JSWARM_JAR_PATH}
RUN chmod 755 ${JSWARM_JAR_PATH}
COPY --from=downloader /${JSWARM_JAR_NAME} ${JSWARM_JAR}
RUN chmod 755 ${JSWARM_JAR}

COPY ${JSWARM_RUN} /usr/local/bin/${JSWARM_RUN}

RUN addgroup -S -g 444 ${USER}
RUN adduser -S -u 444 -G ${USER} -h ${HOME} -s /bin/bash -D ${USER}

USER $USER
VOLUME $HOME

ENTRYPOINT ["bash", "-c", "/usr/local/bin/${JSWARM_RUN}"]
