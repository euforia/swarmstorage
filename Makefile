
REV = 0.1.0
NAME = swarm
BIN_NAME = ${NAME}-${REV}

DOMAIN = swarm.local

clean:
	rm -f ./${BIN_NAME}
	rm -f /tmp/domain.cert
	rm -rf /data/swarm/*

build:
	go build -o swarm-${REV} ./cmd/swarm/*.go

init:
	./${BIN_NAME} domaininit -domainid ${DOMAIN}
	./${BIN_NAME} nodeinit -domaincert /tmp/domain.cert
	./${BIN_NAME} deviceinit 
	echo "LOG_LEVEL=DEBUG" >> /data/swarm/conf/node.ini