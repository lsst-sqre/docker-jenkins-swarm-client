all: build

build:
	docker build \
		-t lsstsqre/jenkins-swarm-client .

ldfc:
	docker build \
		--build-arg JSWARM_UID=48435 \
		--build-arg JSWARM_GID=202 \
		-t lsstsqre/jenkins-swarm-client:ldfc .
