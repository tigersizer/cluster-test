# cluster-test: Firing It Up

## Table of Contents

1. [Introduction](README.md)
1. [VirtualBox](cluster-test-01VirtualBoxTemplateVM.md) - template VM creation
1. [CentOS](cluster-test-02CentOSTemplateVM.md) - template VM configuration
1. [Copying the VM](cluster-test-03CopyVMs.md)
1. [VM customization](cluster-test-04Customization.md)
1. [Firing It Up](#firing-it-up)
    1. [STACK VMs](#stack-VMs)
        1. [The First Time](#the-first-time)
        1. [docker run](#docker-run)
    1. [OPS VM](#ops-VM)
        1. [prettyZoo](#prettyzoo)
        1. [Puslar Manager](#pulsar-manager)
        1. [Prometheus](#prometheus)
    1. [DEV VM](#dev-vm)
1. [Recovering from Mistakes](cluster-test-06Recovery.md)
1. [Testing Failure Modes](cluster-test-07Testing.md)


## Firing it Up

There are two ways to do this: Fire up the whole stack with logs 
or bring up each service in its own window/tab and let the logs scroll.

### STACK VMs

If you're not logged into all the cluster nodes, do so.

#### The First Time

Unless you are **far** more confident than I, I recommend bringing everything up the first time component-by-stack-by-component.

That is, one each stack machine - going through each one for each step. I recommend doing most of these in its own terminal window tab so you can leave the tails running.

If any of these commands do not work, there was an `ln -s` step missed. They're all in the stackX/bin directory. You can figure out what's missing and link it or run them from there with the "./" prefix.

**Prometheus OS monitor**

```
    pnodeup
    pnodetail
```

It's short. If all is working it ends with:

```
    ts=long-ISO-date/time caller=node_exporter.go:199 level=info msg="Listening on" address=0.0.0.0:9090
```

There is not much point in saving this one. Just break out of the tail (ctrl-C) and keep going.

**Prometheus Docker monitor**

```
    pdockup
```

Nothing to tail for this one. You need to satified with no `docker run` errors. Testing it can be done with Prometheus on the Ops machine.


**ZooKeeper**

```
    zooup
    zootail
```

You want to see messages with LEADER and/or FOLLOWER in them. There may be the occasional exception stack dump; that seems to be normal. Note that is only the first time. If you're bring up normally, you will see a message with UPTODATE in it:

```
    timestamp [QuorumPeer[myid=1](plain=0.0.0.0:2181)(secure=disabled)] INFO  org.apache.zookeeper.server.quorum.Learner - Learner received UPTODATE message
```

Things go very sideways if ZooKeeper is unhappy. It's worth jumping over to the Ops machine and [firing up prettyZoo](#prettyzoo) to see if they're all working.

**BookKeeper**

Do **NOT** do this unless the ZooKeepers are happy. [Recovery is unpleasant](cluster-test-06Recovery.md).

```
    bookieup
    bookietail
```

You want to see:

```
    timestamp [main] INFO  org.apache.bookkeeper.common.component.ComponentStarter - Started component bookie-server.
```

**Pulsar Brokers**

```
    brokerup
    brokertail
```

You want to see:

```
    timestamp [main] INFO  org.apache.pulsar.PulsarBrokerStarter - PulsarService started.
```

**Pulsar Proxy**

You only need of these, but there is no harm in three.

```
    proxyup
    proxytail
```

You want to see:

```
    timestamp [main] INFO  org.apache.pulsar.proxy.server.WebServer - Server started at end point http://0.0.0.0:8080
```

**Cassandra**

You don't want to rush cass2 and cass3 (assuming you're doing them in 1,2,3 order, which is not required). It takes a while for nodes to join the cluster. On the bright side, the "too soon" one just yells at you and stops. Just try it again.

```
    cassup
    casstail
```

You want to see:

```
    INFO  [main] timestamp CassandraDaemon.java:650 - Startup complete
```

It may take a while.

After all the Cassandra nodes are up, double-check it:

```
    nodetool status
```

You want to see:

```
    Datacenter: cluster.test
    ========================
    Status=Up/Down
    |/ State=Normal/Leaving/Joining/Moving
    --  Address        Load       Tokens       Owns (effective)  Host ID                               Rack
    UN  192.168.2.201  277.59 KiB  256          70.3%             f839c5b5-7129-4aab-b6ad-a87d14ec5ae7  stack1
    UN  192.168.2.202  280.79 KiB  256          65.4%             66e3da0f-87ba-43d2-9da4-43cae018fc42  stack2
    UN  192.168.2.203  347.38 KiB  256          64.3%             f7e7b39f-4d05-4439-b246-5fbd7ef91279  stack3
```

And you're up and running!

#### Nominal Usage

That entire process can be shortcut with the `stackup` command. It all the xxxup commands above one after the other.

Not everything must be running all the time. 

Pulsar is the hog, requiring: zooup, bookie, and brokerup (proxyup in many cases).

Cassandra will run by itself.

If you're not monitoring, you don't need the Prometheus pieces. I do recommend building at least one Grafana dashboard, even if it's useless, just to see what's involved so if you ask for one from the operations folks, you understand the work involved. Unless you've moved the BIND/named service to one of the stack machines, you have the Ops machine built, play with it, too. That's why *I* built it in the first place.

### OPS VM

Short version: opsup


#### prettyZoo

#### Pulsar Manager

#### Prometheus

### DEV VM

The entire point of this machine is that nothing runs on it. You can do whatever you want to it.

Have fun!
