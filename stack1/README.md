# cluster-test Stack1

This is the only stackX/README.md file with any significant content.

## Table of Contents

1. [Stack Common](../common/README.md)
1. [Stack 1 Specifics](#stack1-specifics)
    1. [bin Directory](#bin)
        1. [Scripts](#scripts)
        1. [Commands](#commands)
    1. [conf Directory](#conf)
        1. [ZooKeeper Configuration](#zookeeper)
        1. [BookKeeper Configuration](#bookkeeper)
        1. [Pulsar Broker Configuration](#pulsar-broker)
        1. [Cassandra Configuration](#cassandra)
        1. [Logstash Configuration](#logstash)
        1. [Retrieving Docker Configuration](#retrieving-docker-configuration)
    1. [Component Directories](#component-directories)
1. [Stack 2 Specifics](../stack2/README.md)
1. [Stack 3 Specifics](../stack3/README.md)
1. [Ops Specifics](../ops/README.md)
1. [Dev Specifics](../dev/README.md)

## Stack1 Specifics

Everything is basically the same for all three stacks, with only minor tweaks. The long description is here. The other stackX/README.md files only contain differences from this documentation. 

Specifics for the first node in the clusters:

### bin

These are all `bash` scripts, but they come in two flavors:

#### Scripts

In order to get persistent logs, one must override Docker's behavior. That's what the `start` .sh shell scripts do.

`start_zk.sh` requires an environment variable, `ZK_ID`. Getting a ZooKeeper started requires knowing its "server id" and this is the best I could do.

#### Commands

Typing long `docker` commands got old, so I shortened them. That's what the not-.sh sell scripts do. Part of the buildstack process is to create links to these from the ~/bin directory. The content is different for each stack, but the names are all the same.

- fooup. Starts the foo image in a container. It does *not* start the container. It wipes the container out before starting a new one.
- foodown. `docker stop` the container. It does not remove the container so you can examine it before wiping it out on the next "up".
- fooltail. `tail -f` the logs. The behavior is a bit different depending on which "foo".

The fooup scripts are the only ones worth detailing, but see the commments in the (stack1 version) scripts, themselves. No need to repeat it all here.

### conf

This directory contains the configuration files. 

Listed in the order they are used.

#### ifcfg-enp0s3

This is the one it is dangerous to just deploy, if you're not me. This is a full copy of my version. All of it is not necessary, but it's easier to just copy the entire thing than write a script that merges bits together.

#### ZooKeeper

The main headache with ZooKeeper is that it talks to itself. It's easy to configure the *other* nodes, but configuring onesself is different. Each configuration file has one "0.0.0.0" IP address. This is for serverX, where X is the ZK_ID used on startup - but not connected; if you change ZK_ID, you must also edit the configuration.

The secondary headache is that port 3888 cannot be overridden with configuration. You can, of course, map it on the `docker run` command, but that doesn't work for the "talking to onesself" connection.

As far as I can tell, that makes it impossible to run two different ZooKeeper nodes on the same machine.

I had a stand-alone ZooKeeper, [dockerhub zookeeper](https://hub.docker.com/_/zookeeper). This worked fine. However, one is included with the Pulsar image and the stand-alone BookKeeper was a nightmare, so I switched to the Pulsar version.

Why put that in the configuration documentation? Because the Docker image builders **change all the environment variable names!!!** This is the main reason I switched to full configuration files: Only one environment variable or mount point to deal with.

The changes:
- dataDir is set to the `docker run` mount point: data/zookeeper; "data" is added automagically.
- electionPortBindRetry is zero, which means "try indefinitely"; this prevents needing to get all three of them up in six seconds (the default).
- admin.enableServer is set to true; apparently everyone knows it is awful and no one uses it.
- admin.serverPort, which could have been remapped with `docker run`.
- server.X are zooX.cluster.test except for "me" (server.1 for stack1), which is 0.0.0.0; see above.

#### BookKeeper

The main headache with BookKeeper is that it really, really doesn't like changes. This is (probably) a good thing for production, but it can be annoying in development - especially when getting it working the first time. If you have Bookies that refuse to start with cookie errors, this is what's happening. See the [Recovery document](../cluster-test-06Recovery.md) for instructions on how to fix it.

I had a stand-alone BookKeeper, [dockehub apache/bookkeeper](https://hub.docker.com/r/apache/bookkeeper), but getting to work with Pulsar was driving me nuts. I switched to the one in the Puslar image.

This is another case of randomly changing environment variable names and availablity, which resulted in using the full configuration file.

The changes:
- journalDirectory is set to the `docker run` mount point: `data/bookkeeper/journal`; "journal" is not added automagically.
- advertisedAddress is set to `bookieX.cluster.test`.
- ledgerDirectories is set to the `docker run` mount point: `data/bookkeepers/ledgers`; "ledgers" is not added automagically.
- prometheusStatsHttpPort is set to `8082`, which could have been mapped in the `docker run` command. 
- httpServerEnabled is set to `true` (mainly for Prometheus).
- httpServerPort is set to `8082` to match the prometheus port, as recommended.
- zkServers is set to `zoo1.cluster.test:2181,zoo2.cluster.test:2181,zoo3.cluster.test:2181`.

#### Pulsar Broker

This was the least painful, although I had gained experience by this point.

The changes:
- zookeeperServers is set to `zoo1.cluster.test:2181,zoo2.cluster.test:2181,zoo3.cluster.test:2181`
- configurationStoreServers is set to `zoo1.cluster.test:2181,zoo2.cluster.test:2181,zoo3.cluster.test:2181`
- webServicePort is `8083`, which could have been mapped in the `docker run` command

#### Cassandra

Lions, tigers, and bears! Cassandra configuration is brutal.

It has an entire directory of configuration: etccassandra under conf. This is mounted at `/etc/cassandra`, hence the name.

**IP Addresses** There are IP addresses in this configuration; Cassandra _requires_ it.

Despite having local configuration files, the Cassandra Docker image writes to them. The `docker run` enviroment variables are *required*.
```
    -e CASSANDRA_BROADCAST_ADDRESS=[YOUR-NODE-IP-ADDRESS] \
    -e CASSANDRA_SEEDS=[FIRST-CLUSTER-NODE-IP-ADDRESS] \
```

Thanks to [Ralph's Open Source Blog](https://ralph.blog.imixs.com/), in a post about [setting up a secure Docker cluster](https://ralph.blog.imixs.com/2020/06/22/setup-a-public-cassandra-cluster-with-docker/), which is a bit more than I want to bite off, just yet.

The changes:
- rename (or delete) `cassandra-topology.proprties`; it is yet more IP addresses.
- cassandra-environment.sh gets a new line: `JVM_OPTS="$JVM_OPTS -javaagent:/casslib/jmx_prometheus_javaagent-0.16.1.jar=8084:/etc/cassandra/jmx_exporter.yml"`
- in cassandra-rackdc.properties `dc` is set to "cluster.test" and `rack` to "stackX"
- I _tried_ to edit `cassandra.yaml` but Cassandra itself insist up rewriting it. 

The as-I-write-this current options result in Cassandra committing, but not using, a tremendous amount of memory. I want to reconfigure that, but I haven't gotten to it, yet.

### logstash

See the [README.md file](conf/logstash/README.md)

### Retrieving Docker Configuration

These are *not* the standard configuration files because the Docker packaging people screw with things. 
You do not need to do this, because I already have. However, for future reference:

All the `docker run` command map a /logs volume. The easiest way to get these files is to get *anything* started without the /conf volume mapped, whether it is functional or not, then do the following:

From the documentation, find out where the configuration file is located, copy it out of the container, move it to the conf directory, edit it to your heart's content, then add the /conf volume mapping.

This example is for Cassandra, since it has an entire directory of configuration files.

```
    $ cassup
    $ docker exec -it cass1 /bin/bash

    # mkdir /logs/etccassandra
    # cp -r /etc/cassandra/* /logs/etccassandra
    # exit

    $ mkdir ~/cluster-test/stack1/conf/etccassandra
    $ copy -r ~/cluster-test/stack1/cassandra/logs/etccassandra/* ~/cluster-test/stack1/conf/etccassandra
```

Getting the configuration for the others is much the same, but with only a single file involved. 

## Component Directories

We need a place for persistence. Docker does odd things with permissions and some of the components are odder, yet. You do *not* want to let these auto-create via the `docker run` command. They will, but access is often wrong.

These directories are not in git. They are created (and `chgrp` / `chmod` as needed) by the buildstack script. It's in the step-by-step instructions, too.

In general, your user (*stack* if you're following instructions) owns them and they are in the Docker group. There root ownership and groups scattered in subdiretories.

