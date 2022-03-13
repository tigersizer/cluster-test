#!/bin/bash
# bad things happen if this is not created
mkdir -p data/zookeeper
# so an environment variable is required
echo $ZK_ID > data/zookeeper/myid
# save Docker stdout logs to a file (for later pickup)
bin/pulsar zookeeper > /logs/zookeeper1.log 2>&1
