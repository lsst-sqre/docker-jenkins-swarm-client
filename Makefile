all: build

build:
	docker build \
		-t lsstsqre/jenkins-swarm-client .
