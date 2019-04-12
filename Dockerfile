#
# download swarm jar
#
FROM alpine:3.8 as downloader

ARG JENKINS_SWARM_VERSION=3.14
ARG SWARM_JAR_NAME=swarm-client-${JENKINS_SWARM_VERSION}.jar
ARG DL_BASE_URL=https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client

RUN apk add --no-cache --upgrade curl

RUN curl -sSLo /${SWARM_JAR_NAME} \
    ${DL_BASE_URL}/${JENKINS_SWARM_VERSION}/${SWARM_JAR_NAME}

#
# construct swarm agent runtime
#
FROM alpine:3.8

ARG JENKINS_SWARM_VERSION=3.14
ARG SWARM_JAR_NAME=swarm-client-${JENKINS_SWARM_VERSION}.jar
ARG SWARM_JAR_PATH=/usr/share/jenkins
ARG SWARM_JAR=${SWARM_JAR_PATH}/${SWARM_JAR_NAME}
ARG HOME=/j
ARG USER=jenkins-swarm

ENV SWARM_RUN=jenkins-swarm-client-run
ENV JAVA /usr/bin/java
ENV JENKINS_SWARM_JAR=${SWARM_JAR}

RUN apk add --no-cache --upgrade openjdk8 bash git

# install docker client
RUN apk add --no-cache --upgrade docker
RUN chmod u+s /usr/bin/docker

RUN mkdir -p ${SWARM_JAR_PATH}
RUN chmod 755 ${SWARM_JAR_PATH}
COPY --from=downloader /${SWARM_JAR_NAME} ${SWARM_JAR}
RUN chmod 755 ${SWARM_JAR}

COPY ${SWARM_RUN} /usr/local/bin/${SWARM_RUN}

RUN addgroup -S -g 444 ${USER}
RUN adduser -S -u 444 -G ${USER} -h ${HOME} -s /bin/bash -D ${USER}

USER $USER
VOLUME $HOME

ENTRYPOINT ["bash", "-c", "/usr/local/bin/${SWARM_RUN}"]
