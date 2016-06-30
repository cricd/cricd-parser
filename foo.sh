docker network create --driver bridge cricd-network
docker run -d --net=cricd-network -p 1337:1337 bradleyscott/cricd-entities
docker run -d -p 1113:1113 -p 2113:2113 eventstore/eventstore-docker --net=cricd-network




