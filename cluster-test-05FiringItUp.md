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
        1. [Grafana](#grafana)
    1. [DEV VM](#dev-vm)
        1. [Testing Cassandra](#testing-cassandra)
1. [Recovering from Mistakes](cluster-test-06Recovery.md)
1. [Testing Failure Modes](cluster-test-07Testing.md)


## Firing it Up

There are two ways to do this: Fire up the whole stack with logs 
or bring up each service in its own window/tab and let the logs scroll.

### STACK VMs

If you're not logged into all the cluster nodes, do so.

#### The First Time

Unless you are **far** more confident than I, I recommend bringing everything up the first time component-by-stack-by-component.

That is, one component on each stack machine - going through each one for each step. I recommend doing most of these in its own terminal window tab so you can leave the tails running.

If any of these commands do not work, there was an `ln -s` step missed. They're all in the stackX/bin directory. You can figure out what's missing and link it or run them from there with the "./" prefix.

**Prometheus OS monitor**

```
    pnodeup
    pnodetail
```

It's short. If all is working it ends with:

```
    ts=long-ISO-dateZtime caller=node_exporter.go:199 level=info msg="Listening on" address=0.0.0.0:9090
    ts=long-ISO-dateZtime caller=tls_config.go:195 level=info msg="TLS is disabled." http2=false
```

There is not much point in saving this one. Just break out of the tail (ctrl-C) and keep going.

**Prometheus Docker monitor**

```
    pdockup
```

The output will be something like this:

```
    d5f790405535198233def55048f3f4b0d6193d4d4c4f6eb61d0c6fa36e70c250
    Error response from daemon: No such container: pdock1
    Error: No such container: pdock1
    Unable to find image 'cAdvisor' locally
```

- the large hex number is the docker id of the network (created by netup)
- the first error is the `docker stop` command, but it does not yet exist to be stopped.
- the second error is the `docker rm` command, but it does not yet exist to be removed.

Followed by a bunch of downloading status/information and finally another large hex number.

Nothing to tail for this one. You need to satified with no `docker run` errors. Testing it can be done with Prometheus on the Ops machine.

**ZooKeeper**

```
    zooup
    zootail
```

The `zooup` output will be very similar to the `pdockup` output, for the same reaons, with the first line being:

```
    Error response from daemon: network with name vm-bridge already exists
```

Because `netup` has already been run.

You will see:

```
    java.net.NoRouteToHostException: No route to host (Host unreachable)
```

and its stack trace until the other zoos come up. Nothing to worry about.


You want to see messages with UPTODATE in it:

```
    timestamp [QuorumPeer[myid=1](plain=0.0.0.0:2181)(secure=disabled)] INFO  org.apache.zookeeper.server.quorum.Learner - Learner received UPTODATE message
    timestamp [QuorumPeer[myid=1](plain=0.0.0.0:2181)(secure=disabled)] INFO  org.apache.zookeeper.server.quorum.QuorumPeer - Peer state changed: following - broadcast
```

Things go very sideways if ZooKeeper is unhappy. It's worth jumping over to the Ops machine and [firing up prettyZoo](#prettyzoo) to see if they're all working.

**BookKeeper**

Do **NOT** do this unless the ZooKeepers are happy. [Recovery is unpleasant](cluster-test-06Recovery.md).

bookie1 has some Pulsar cluster intialization code it runs the first time. This spews out messages. It should all work, but it's hard to tell. I've never had a problem with it, so I haven't bother saving the output for later analysis.

```
    bookieup
    bookietail
```

The by-now usual docker complaints. 
You want to see:

```
    timestamp [main] INFO  org.apache.bookkeeper.common.component.ComponentStarter - Started component bookie-server.
```

as more nodes come up, you will see:

```
    timestamp [BookKeeperClientScheduler-OrderedScheduler-0-0] INFO  org.apache.bookkeeper.net.NetworkTopologyImpl - Adding a new node: /default-rack/bookie3.cluster.test:3181
```

**Pulsar Brokers**

```
    brokerup
    brokertail
```

After the usual docker messages, you want to see:

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

It may take a while. As the not-first nodes are coming up, you will see things such as this:

```
    INFO  [HANDSHAKE-/192.168.2.202] timestamp OutboundTcpConnection.java:561 - Handshaking version with /192.168.2.202
```

on the up nodes and on the coming up node:

```
INFO  [main] timestamp StorageService.java:1564 - JOINING: Finish joining ring
INFO  [main] timestamp Gossiper.java:1832 - Waiting for gossip to settle...
INFO  [main] timestamp StorageService.java:1564 - JOINING: sleeping 30000 ms for pending range setup
INFO  [HANDSHAKE-/192.168.2.203] timestamp OutboundTcpConnection.java:561 - Handshaking version with /192.168.2.203
INFO  [GossipStage:1] timestamp Gossiper.java:1163 - Node /192.168.2.203 is now part of the cluster
```

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

That entire process can be shortcut with the `stackup` command. It executes all the xxxup commands above one after the other.

Not everything must be running all the time. 

Pulsar is the hog, requiring: zooup, bookie, and brokerup (proxyup in many cases).

Cassandra will run by itself, but eats memory like mad.

If you're not monitoring, you don't need the Prometheus pieces. I do recommend building at least one Grafana dashboard, even if it's useless, just to see what's involved so if you ask for one from the operations folks, you understand the work involved. Unless you've moved the BIND/named service to one of the stack machines, you have the Ops machine built, play with it, too. That's why *I* built it in the first place.

### OPS VM

Short version: `opsup`

#### prettyZoo

I love this tool because it is so simple and easy to use. See the [OPS Customization](cluster-test-04Customization.md#prettyzoo) document for how to configure it.

```
    prettyZoo
```

Runs it. It is very chatty on stderr, so there isn't much point in running in the background.

#### Pulsar Manager

This thing is a bear to get running. Do NOT make a mistake or you'll be [starting over](cluster-test-06Recovery.md#pulsar-manager).

Be SURE the cluster is running (e.g. check Prometheus metrics or the Grafana dashboard).

Copy our configuration into it, start it and start it (you MUST be in that directory):

```
    cp ~/cluster-test/ops/conf/application.properties ~/pulsar-manager/pulsar-manager
    cd ~/pulsar-manager/pulsar-manager
    ./bin/pulsar-manager
```

Generate the super-user. This is VERY finicky. In particular, it validates the email address, somehow, and does NOT validate the password, but the login UI does: more than 6 characters or [recover from it](cluster-test-06Recovery.md#pulsar-manager).

```
    CSRF_TOKEN=$(curl http://ops.cluster.test:7750/pulsar-manager/csrf-token)
    curl \
    -H "X-XSRF-TOKEN: $CSRF_TOKEN" \
    -H "Cookie: XSRF-TOKEN=$CSRF_TOKEN;" \
    -H 'Content-Type: application/json' \
    -X PUT http://ops.cluster.test:7750/pulsar-manager/users/superuser \
    -d '{"name": "admin", "password": "cluster-test", "description": "cluster.test test cluster", "email": "ctest@test.org"}'
```

You very much want to see:

```
    {"message":"Add super user success, please login"}
```

Open a browser and 
- Go to `http://ops.cluster.test:7750/ui/index.html`.
- It will redirect to a login page.
- Login with credentials from above.
- Boookmark where you end up.

When creating new environments, note that the "Service URL" is a broker URL, which is http://brokerX.cluster.test:8083/

Create the "environment":
- Press the button
- Enter whatever for the name (e.g. ClusterTest).
- Enter a broker URL (e.g. http://broker1.cluster.test:8083/).

Clicking on the environment name will show you what's inside.

You want see "pulsar-cluster-test" twice: Once for the pulsar tenant and once for the public tenant.


#### Prometheus

```
    prometheusup
    promethetail
```

I hope you've gotten the hang of that by now. You want to see:

```
    ts=long-ISO-dateZtime caller=main.go:897 level=info msg="Server is ready to receive web requests."
```

Open a browser and go to prometheus.cluster.test:9090.

If you're doing this in order, go to Status/Targets. There will be a list of all the systems from which metrics are gathered.

You want to see:
- bookies (3/3 up)
- brokers (3/3 up)
- casses (3/3 up)
- dockers (4/4 up)
- prometheus (1/1 up)
- VMs (4/4 up)

Click on the links and explore; that's the point.

The query "language" is a bit odd, but once you get used it, it's quite nice. Grafana uses it more-or-less directly, so you can test out pieces of you Grafana queries here.

The documentation is good. [Start here](https://prometheus.io/docs/prometheus/latest/querying/basics/).

#### Grafana

```
    grafanaup
    grafanatali
```

You want to see:

```
    t=long-ISO-dateZtime lvl=info msg="HTTP Server Listen" logger=http.server address=[::]:3000 protocol=http subUrl= socket=
```

Open a browser and go to grafana.cluster.test:3000

The default login is "admin"/"admin"; it asks you to change it right away, but isn't pissy about what you type.

The first thing to do is add Prometheus as a Data source.
- Hover the mouse over the gear-looking thing on the left.
- "Configuration" will show up.
- Click "Data sources".
- Click "Add data sources"
- Prometheus shows up near the top; Pick it
- The URL is all that must be set: http://prometheus.cluster.test:9090
- Scroll the the bottom and press the Save & test button.

You want "Successfully tested" popupy thing. It will fade away on its own.

The Dashboards can now be imported:
- Press the plus-sign thing on the left.
- "Create" will show up.
- Click "Import".
- Click the "Upload JSON file" button.
- Navigate to ctest/cluster-test/ops/conf/grafana.
- Pick one.
- Open it.
- Press the "Import" button.

### DEV VM

The entire point of this machine is that nothing runs on it. You can do whatever you want to it.

Have fun!

#### Testing Cassandra

To be sure this is all working, there is a CQL script that writes to cass1 and a silly Python test program that reads back from cass3.

```
    cd ~/cluster-test/dev/casstest
    ./test
```

You should see a list of the machines in the ops/conf/cluster.test.db file.

#### Testing Pulsar

The "all default" Python connections work strangely. Start the subscriber first. To kill it, press ctrl-C, then send a message from the publisher.

You want two terminal windows for this. In one:

```
    python ~/cluster-test/dev/pulsartest/subscriber.py
```

In the other:

```
    python ~/cluster-test/dev/pulsartest/publisher.py
```

Type messages into the publisher and they will show up on the subscriber. You can watch the Broker dashboard and Pulsar Manager to see things changing.

