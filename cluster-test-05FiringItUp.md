# cluster-test: Firing It Up

## Table of Contents {#toc}

1. [Cluster Nodes](#Running-cluster)
    1. [docker-compose](#Running-compose)
    1. [docker run](#Running-run)
1. [OPS VM](#Running-ops)
    1. [prettyZoo](#Running-prettyzoo)
    1. [Puslar Manager](#Running-pmanager)
1. [DEV VM](#Running-dev)

## Firing it all up {#Running}

There are two ways to do this: Fire up the whole stack with logs 
or bring up each service in its own window/tab and let the logs scroll.

### Cluster Nodes {#Running-cluster}

If you're not logged into all the cluster nodes, do so.

#### docker-compose {#Running-compose}

If you use the `docker-compose` method, the entire stack will start at once and write log files.
The OPS VM will deal with logs, if they are generated. 

```
    $ stackup
```

That's it. Do it on each cluster node.

Note that this method does not require a GUI. This can be done via putty, if so desired. The server
is installed and active by default, so there is nothing to install or configure.

#### docker run {#Running-run}

If you use the `docker run` method, it's a bit longer and the OPS machine will have no logs to gather. 
After each command, open a new window or tab for the next one:

```
    $ zooup
    $ bookieup
    $ brokerup
    $ cassup
```

On one node you will probably want the Pulsar proxy service, so pick one and:

```
    $ proxyup
```

### OPS VM {#Running-ops}

I have no idea; I haven't created it, yet.

#### prettyZoo {#Running-prettyzoo}

### DEV VM {#Running-dev}

The entire point of this machine is that nothing runs on it. You can do whatever you want to it.

Have fun!

## Recovering from Mistakes {#Recovering}

This can be difficult because the entire point of all this clustering is redundancy. 

If you need to start from scratch after running bookies, you will need to wipe the ZooKeeper data, which will
require starting Pulsar from scratch, too.

Cassandra also likes its redundancy and bringing the cluster up and down moves a lot of data. If you're doing
Cassandra work, I recommend leaving it running and putting the host to "sleep" rather than powering it down.

## Testing Failure Modes {#Testing}

That is one of the points of this elaborate setup. 

All of the "up" commands have matching "down" commands:
- `stackdown` will bring down all the services on the node.
- `zoodown` will `docker stop` the ZooKeeper service on the node on which it is run.
- `bookiedown` the same with the BookKeeper service.
- `brokerdown` the same with the Pulsar Broker service.
- `cassdown` the same with the Cassandra node.
- `proxydown` exists primarily for completeness.



