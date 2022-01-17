# cluster-test: Recovering from Mistakes

## Table of Contents

1. [Introduction](README.md)
1. [VirtualBox](cluster-test-01VirtualBoxTemplateVM.md) - template VM creation
1. [CentOS](cluster-test-02CentOSTemplateVM.md) - template VM configuration
1. [Copying the VM](cluster-test-03CopyVMs.md)
1. [VM customization](cluster-test-04Customization.md)
1. [Firing it all up](cluster-test-05FiringItUp.md)
1. [Recovering from Mistakes](#recovering-from-mistakes)
    1. [BookKeeper Changes](#bookkeeper-changes)
    1. [Pulsar Manager](#pulsar-manager)
1. [Testing Failure Modes](cluster-test-07Testing.md)

## Recovering from Mistakes

This can be difficult because the entire point of all this clustering is redundancy. 

If you need to start from scratch after running bookies, you will need to wipe the ZooKeeper data, which will
require starting Pulsar from scratch, too.

Cassandra also likes its redundancy and bringing the cluster up and down moves a lot of data. If you're doing
Cassandra work, I recommend leaving it running and putting the host to "sleep" rather than powering it down.

### BookKeeper 

#### BookKeeper Changes

BookKeeper has two cookies: One locally in the data directory and one in ZooKeeper. When those cookies do not match, it refuses to start. The error message will look like this:

```
    01:56:34.017 [main] ERROR org.apache.bookkeeper.server.Main - Failed to build bookie server
    org.apache.bookkeeper.bookie.BookieException$InvalidCookieException: Cookie
```

This is a dandy production feature to keep one from accidentally wiping out data by bringing up a misconfiged bookie. However, during development it can be annoying. Hopefully, I have made most of those mistakes for you. In case I have not:

Delete everything in the local data directory, where "stackX" below is 1, 2, or 3 (or all of them) depending on which bookie will not start.

```
    $ sudo rm -rf ~/cluster.dev/stackX/bookkeeper/data/*
```

If you remove the directory itself, watch permissions. Docker will recreate it as root owned. This may or may not matter to you. I find it annoying, but not fatal.

Delete the ZooKeeper cookie. You can either use [prettyZoo](cluster.dev-04Customization.md#VMs-prettyzoo) or wipe all of ZooKeeper, which has Pulsar implications, although I'm not sure what they are.

To remove them via prettyZoo, fire it up (on ops.cluster.dev):

```
    $ prettyZoo 
```

- Connect to any node in the cluster. If you haven't configured it, see the link above.
- Open the "ledgers" toggle.
- Open the revealed "cookies" toggle.
- Select the problem bookie (host:3181).
- Delete it, by right-clicking and choosing the "delete" option.
- Confirm the deletion.

### Pulsar Manager

#### Blank Web Page

Running it locally (as opposed to in Docker), the most likely reason for this is starting it outside it's home directory. It really, really wants to start from ~/pulsar-manager/pulsar-manager.


#### Wiping it from ZooKeeper

It uses herdDB, whatever that is, and it's configured to use the ZooKeeper cluster. If you need to start over, you need to wipe that out. Just as above, either wipe the cluster entirely or use prettyZoo.

Be sure Pulsar Manager is not running (pmandown).

It's easy to remove because it's all in one place:

- Connect to any cluster. If you haven't configured it, see the link above.
- Select the "herd" entry.
- Delete it.

#### Pulsar Admin Exceptions

The metadata initiation step, which is performed on the first bookie1 startup, is probably wrong.

### Prometheus

Almost everything that goes wrong with Prometheus, itself, is a bad port.

Double-check that the configured web ports and the docker run port mapping is correct.

### PromQL

This lives between Prometheus and Grafana because it applies to both.

#### regex

There both positive and negative regular expression matches.

**Positive Regex**
Look at `container_memory_max_usage_bytes` in Prometheus. It has named and unnamed metrics. To display only the named ones, use `name=~".+"` - i.e. name is anything.

**Negative Regex**
Look at `pulsar_producers_count` in Prometheus. It has topiced and untopiced metrics. To display only the unnamed ones, use `topc!~".0"` - i.e. no name attribute.

### Grafana

#### Extra Docker Metrics

The metrics, themselves, contain a docker id; it is not displayed. If you up/down/up the component, it gets a different docker id, even though it has the same name. This results in apparently duplicated legend entries in Grafana.

#### Horrible Legend Names

First step, use braces to shorten it without losing context. For example, `pulsar_producers_count` has instance values such as `instance="broker1.cluster.test:8083"` set the legend to {{instance}} and the instance name will replace the super-long metric attribute string.

Use a Transform, Rename with regex. The dashboards are full of these. The nominal `instance` value is `instance="broker1.cluster.test:8083"`. Create a Transform, which is a per-panel thing, to shorten it: `(broker.)\..*` maps to `$1`

