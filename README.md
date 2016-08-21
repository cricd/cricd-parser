# cricd-parser

Cricd-parser is a parser for the YAML game files found from cricsheet.org to cricd-events. It watches a folder for new YAML files, parses them and then pushes them to EventStore. 

## Running the service in Docker

The parser requires a cricd-entities instance, an EventStore instance and a directory to watch. These variables are configured using the following environment variables:
 - ENTITYSTORE_IP
 - ENTITYSTORE_PORT
 - EVENTSTORE_IP
 - EVENTSTORE_PORT
 - EVENTSTORE_STREAM_NAME

The watch directory needs to be passed as a docker volume.  You can specify these parameters when running the docker container. 
For example:

```docker run -d -e ENTITYSTORE_IP=172.18.0.2 -e ENTITYSTORE_PORT=1337 -e EVENTSTORE_IP=172.18.0.3 -e EVENTSTORE_PORT=2113 -e EVENTSTORE_STREAM_NAME=cricket_events -v /games/:/app/games ryankscott/cricd-parser```

If your EventStore instance is running in a Docker container as well then network connectivity will need to be established between these instances. This is explained in the Docker networking documentation but the steps at a high level are: 1. Create a user defined network using a command like docker network create --driver bridge cricd-network 2. Start your EventStore container using the --network parameter docker run --net=cricd-network 3. Find the IP address of the EventStore container using the command docker network inspect cricd-network 4. Start this Docker container using the --net=cricd-network parameter and using the EVENTSTORE_IP variable set to the IP address you just found
