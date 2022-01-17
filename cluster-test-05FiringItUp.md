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
        1. [Nominal Cold Start](#nominal-cold-start)
        1. [Nominal Warm Start](#nominal-warm-start)
    1. [OPS VM](#ops-VM)
        1. [prettyZoo](#prettyzoo)
        1. [Puslar Manager](#pulsar-manager)
        1. [Prometheus](#prometheus)
        1. [Grafana](#grafana)
        1. [Elasticsearch](#elasticsearch)
    1. [DEV VM](#dev-vm)
        1. [Testing Cassandra](#testing-cassandra)
        1. [Testing Pulsar](#testing-pulsar)
1. [Recovering from Mistakes](cluster-test-06Recovery.md)
1. [Testing Failure Modes](cluster-test-07Testing.md)


## Firing it Up

There are two ways to do this: Fire up the whole stack with logs 
or bring up each service in its own window/tab and let the logs scroll.

### STACK VMs

If you're not logged into all the cluster nodes, do so.

#### The First Time

Unless you are **far** more confident than I, I recommend bringing everything up the first time component-by-stack-by-component. The first time is also going to be doing a lot of `docker pull`; massive parallel tends to slow that down because your Internet connection saturates. 

That is, one component on each stack machine - going through each one for each step. I recommend doing each of these in its own terminal window tab so you can leave the tails running.

If any of these commands do not work, there was an `ln -s` step missed. They're all in the stackX/bin directory. You can figure out what's missing and link it or run them from there with the "./" prefix.

**Prometheus OS monitor**

`pnodeup` should run as part of .bashrc - if you're following instructions. Otherwise, do it now:

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
- the first error is the `docker stop` command, but the container, pdock1, does not yet exist to be stopped.
- the second error is the `docker rm` command, but the container, pdock1, does not yet exist to be removed.

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

**Postgres**

These are independent. I needed one, so I did all three to keep the stacks symmetric. Perhaps later I'll add replication or something that ties them together.

```
    postgresup
    postgrestail
```

The first time up, it creates a database and restarts itself.

It doesn't log much. At the end, you want to see:

```
    timstamp [1] LOG:  database system is ready to accept connections
```

**postgres-exporter**
This exports Postgres metrics to Prometheus. 

```
    ppgresup
    ppgrestail
```

You want to see something like this:

```
ts=2022-01-15T22:50:16.582Z caller=main.go:123 level=info msg="Listening on address" address=:9187
ts=2022-01-15T22:50:16.583Z caller=tls_config.go:195 level=info msg="TLS is disabled." http2=false
ts=2022-01-15T22:50:18.274Z caller=server.go:74 level=info msg="Established new database connection" fingerprint=postgres2.cluster.test:5432
ts=2022-01-15T22:50:18.280Z caller=postgres_exporter.go:662 level=info msg="Semantic version changed" server=postgres2.cluster.test:5432 from=0.0.0 to=14.1.0
```

That's all it does; no point in leaving the tail open.

And you're up and running!

#### Nominal Cold Start

That entire process can be shortcut with the `stackup` command. It executes all the xxxup commands above one after the other.

Not everything must be running all the time. 

Pulsar is the hog, requiring: zooup, bookie, and brokerup (proxyup in many cases).

Cassandra will run by itself. It eats memory like mad.

If you're not monitoring, you don't need the Prometheus pieces. I do recommend building at least one Grafana dashboard, even if it's useless, just to see what's involved so if you ask for one from the operations folks, you understand the work involved. Unless you've moved the BIND/named service to one of the stack machines, you have the Ops machine built, play with it, too. That's why *I* built it in the first place.

Everything is configured with `--restart always`. A cold start will only happen if you `down` the containers; either one-by-one or with `stackdown`.

#### Nominal Warm Start

If you power-down the VMs without running `down` commands, everything will restart on power-up.

This sometimes, mostly works. 

I recommend at least Prometheus so you can check the Status / Targets page to see what's running.

Brokers seem to have issues with warm starts, but intermittently. Cassandra will be OK, if you don't start the VMs in parallel. That is, let one come up (at least to the login screen) before starting the next.

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

```
    pmanup
```

`pmantail` works, but nothing interesting is logged.

Generate the super-user. This is VERY finicky. In particular, it validates the email address, somehow, and does NOT validate the password, but the login UI does: more than 6 characters or [recover from it](cluster-test-06Recovery.md#pulsar-manager).

```
    CSRF_TOKEN=$(curl http://ops.cluster.test:7750/pulsar-manager/csrf-token)
    curl \
    -H "X-XSRF-TOKEN: $CSRF_TOKEN" \
    -H "Cookie: XSRF-TOKEN=$CSRF_TOKEN;" \
    -H 'Content-Type: application/json' \
    -X PUT http://ops.cluster.test:7750/pulsar-manager/users/superuser \
    -d '{"name": "admin", "password": "clustertest", "description": "cluster.test test cluster", "email": "ctest@test.org"}'
```

You very much want to see:

```
    {"message":"Add super user success, please login"}
```

Open a browser and 
- Go to `http://ops.cluster.test:7750/ui/index.html`.

If that fails with an error page, you're just screwed. I can't get it working, again.

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
- postgreses (3/3 up)
- prometheus (1/1 up)
- VMs (5/5 up)

Click on the links and explore; that's the point.

The query "language" is a bit odd, but once you get used it, it's quite nice. Grafana uses it more-or-less directly, so you can test out pieces of your Grafana queries in Prometheus, which has a lot more screen real-estate and better error messages.

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
- Set the Prometheus Data Source.

These are very tall dashboards. I wanted the green/red stuff across my screen. The top of the windows have inches of header information; the bottom does not. So I made the VM window full-screen height and the Firefox windows inside it full height, too. I can then open other stuff over the top of it and the gauges stay visible without cluttering up the screen with title bars, tabs, and menus.

Browse the [Grafana Dashboards](https://grafana.com/grafana/dashboards/). Some of them work fine (e.g. Node Exporter Full #1860) and nicely compliment my overviews (which are just thrown together). Some of them do not (e.g. cassandra-monitoring).

#### Elasticsearch

This is copied almost exactly from the [Elasticsearch instructions](https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html).
```
    elasticup
    elastictail
```

It doesn't seem to have a good "I'm up" log statemnt. This seems likely:

```
    {"type": "server", "timestamp": "2021-12-25T20:31:35,446Z", "level": "INFO", "component": "o.e.c.r.a.AllocationService", "cluster.name": "docker-cluster", "node.name": "8760a5894785", "message": "Cluster health status changed from [YELLOW] to [GREEN] (reason: [shards started [[.ds-ilm-history-5-2021.12.25-000001][0]]]).", "cluster.uuid": "DmHz4SkKQge_MN7jg_oc5A", "node.id": "SxwXP3vhSxSO2rF_09eE7w"  }
```

You can test it with:

```
    curl -X GET "localhost:9200/_cat/nodes?v=true&pretty"
```

### gogs

gogs is a git server (written in Go, hence the name). I installed it, at all, because I wanted to have multiple DEV machines running the same proprietary (i.e. not github compatible) code. I installed in on the OPS machine because I only wanted one instance of it and putting it on the DEV machine would have cloned it when I cloned the DEV VM.

This led to a giant battle with VirtualBox shared folders because I thought it would be handy to have the repositories on the Windows machine for backups. That might be handy, but it just doesn't work (file system permission issues - either too strict or too lax; no Goldilocks zone).

This is also what led to adding Postgres to the stack: gogs requires a DB (and I don't trust MySQL licensing, now that Oracle owns it).

The same drill:

```
    gogsup
    gogstail
```

The expected/desired output:

```
    timestamp [ INFO] Listen on http://0.0.0.0:3000
    different-format-timestamp sshd[57]: Server listening on :: port 22.
    different-format-timestamp sshd[57]: Server listening on 0.0.0.0 port 22.
```

You are not done. You must configure the server. Hypriot has a [good guide](https://blog.hypriot.com/post/run-your-own-github-like-service-with-docker/), albeit written for a Rasberry Pi.

Before doing that, you need to make Postgres happy:
- pick a stack/postgres machine to use. 
- psql to it (if you're following instructions, `psql postgres2.cluster.test` will work)
- [Create the user](https://www.postgresql.org/docs/8.0/sql-createuser.html)
    - CREATE USER gogs WITH PASSWORD 'clustertest';
- [Create the database](https://www.postgresql.org/docs/9.0/sql-createdatabase.html)
    - CREATE DATABASE gogs WITH OWNER gogs;

NOW you are ready to open `http://gogs.cluster.test:8086/` in a browser. The install page comes up by default.

In the Database Settings, enter:
- Database Type: PostgresSQL
- Host: postgres2.cluster.test:5432
- User: gogs
- Password: clustertest
- Database Name: gogs
- Schema: public
- SSL Mode: Disable
In the Application General Settings, enter:
- Application Name: Gogs
- Repository Root Path: leave it alone (/data/git/gogs-repositories)
- Run User: git
- Domain: gogs.cluster.test
- SSH Port: 22 (this is the in-container port)
- "Use Builtin SSH Server" is contraindicated.
- HTTP Port: 3000 (this is the in-container port)
- Application URL: http://gogs.cluster.test:8086/ (this is the out-of-container port)
- Log Path: leave it alone (/app/gogs/log - we can always remap with Docker)

Press the Install Gogs button.

Expectation: You are taken to the main web page. Bookmark it.

One last step:
"Register" a user. I used ctest and the tigersizer email address (having no idea what emails it might send, I thought a real address was a good first choice). It seems to contact Gravitar, since I have my blog icon.

*IMPORTANT NOTE:* This configures SSH on a non-standard port (8022). This requires modifying the URLs or adding SSH configuration. See [DEV .ssh files](cluster-test-04Customization.md#ssh-files).

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

