# cluster-test: Testing

## Table of Contents {#toc}

1. [Testing Failure Modes](#Testing)

## Testing Failure Modes {#Testing}

That is one of the points of this elaborate setup. 

All of the "up" commands have matching "down" commands:
- `stackdown` will bring down all the services on the node.
- `zoodown` will `docker stop` the ZooKeeper service on the node on which it is run.
- `bookiedown` the same with the BookKeeper service.
- `brokerdown` the same with the Pulsar Broker service.
- `cassdown` the same with the Cassandra node.
- `proxydown` exists primarily for completeness.



