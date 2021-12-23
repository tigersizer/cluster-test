# cluster-test: Customizing the VMs

## Table of Contents 

This is all manual, mostly command-line, work. But it's all simple, short, and copy/paste.

1. [Introduction](README.md)
1. [VirtualBox](cluster-test-01VirtualBoxTemplateVM.md) - template VM creation
1. [CentOS](cluster-test-02CentOSTemplateVM.md) - template VM configuration
1. [Copying the VM](cluster-test-03CopyVMs.md)
1. [VM customization](#vm-customization)
    1. [OPS VM](#ops-vm)
        1. [BIND](#bind)
        1. [ifcfg](#ops-ifcfg)
        1. [ZooKeeper Admin](#zookeeper-admin)
        1. [prettyZoo](#prettyzoo)
        1. [BookKeeper Admin](#bookkeeper-admin)
        1. [Pulsar Manager](#pulsar-manager)
        1. [Prometheus](#prometheus)
        1. [Elasticsearch](#elasticsearch)
        1. [Grafana](#grafana)
        1. [Kibana](#kibana)
    1. [STACK VMs](#stack-vms)
        1. [ifcfg](#stack-ifcfg)
    1. [DEV VM](#dev-vm)
        1. [ifcfg](#dev-ifcfg)
        1. [github](#github)
1. [Firing it all up](cluster-test-05FiringItUp.md)
1. [Recovering from Mistakes](cluster-test-06Recovery.md)
1. [Testing Failure Modes](cluster-test-07Testing.md)

## VM Customization

Each virtual machine is slightly different (notably the IP addresses).

### OPS VM

We'll do this one first so it's ready to deal with DNS right away. That is the only "do this first" step, here. If you want to hurry and get the cluster up before you can monitor it - I get it. Configure bind/named then skip ahead and come back to this step.

There are two scripts for this:
- `setnet` configures BIND/named and the enp0s3 exactly as mine are; you probably want to do these steps manually so you can change things.
- `buildops` does the rest; this is safe enough that you can just run it - you don't even need to read any of the documentation.

#### BIND

The dangerous way, which will reboot at the end:

```
    .~/cluster-test/ops/bin/setnet
```

You want to do this BEFORE changing your network configuration because it requires access to the Internet and changing your network configuration may break that.


This is almost word-for-word of a [fedingo post](https://fedingo.com/how-to-configure-dns-server-on-centos-rhel/) on installing BIND.

```
    sudo dnf install -y bind bind-utils
    sudo vi /etc/named.conf
```

You want to comment out two lines in options and change one:

```
// commenting these out means listen-on port 53 {0.0.0.0}
//      listen-on port 53 { 127.0.0.1; };
//      listen-on-v6 port 53 { ::1; };

	allow-query     { any; };
```

"any" is not the best choice, but names in local Docker containers need to resolve and adding "127.0.0.11" - the Docker DNS address - was insufficient.

Right after the "." zone, add the new zone:

```
zone "cluster.dev" IN {
        type master;
        file "/var/named/cluster.test.db";
        allow-update { none; };
};
zone "2.168.192.in-addr.arpa" IN {
        type master;
        file "/var/named/192.168.2.db";
        allow-update { none; };
};
```

I'll mention it here, one last time: Change 192.168.2 to whatever works for you. Note that is the reason for all this: To set the network stuff up once and be done with it.

Now create the two (forward and reverse) zone files:

```
    $ sudo vi /var/named/cluster.test.db
@	IN	SOA	ops.cluster.test	root.cluster.test. (
							1001	; Serial
							3H	; Refresh
							15M	; Retry
							1W	; Expire
							1D	; Minimum TTL
							)
; Name server information
@	IN	NS	ops.cluster.test.

; IP of name server
ops	IN 	A	192.168.2.200

; no MX record

;A - host to IP
elastic	IN	A	192.168.2.200
kibana	IN	A	192.168.2.200
prometheus	IN	A	192.168.2.200
grafana	IN	A	192.168.2.200
stack1	IN	A 	192.168.2.201
zoo1	IN	A	192.168.2.201
bookie1	IN	A	192.168.2.201
broker1	IN	A	192.168.2.201
proxy1	IN	A	192.168.2.201
cass1	IN	A	192.168.2.201
stack2	IN	A 	192.168.2.202
zoo2	IN	A	192.168.2.202
bookie2	IN	A	192.168.2.202
broker2	IN	A	192.168.2.202
proxy2	IN	A	192.168.2.201
cass2	IN	A	192.168.2.202
stack3	IN	A 	192.168.2.203
zoo3	IN	A	192.168.2.203
bookie3	IN	A	192.168.2.203
broker3	IN	A	192.168.2.203
proxy3	IN	A	192.168.2.201
cass3	IN	A	192.168.2.203
dev	IN	A	192.168.2.210
```

```
    $ sudo vi /var/named/192.168.2.db
@	IN	SOA	ops.cluster.test	root.cluster.test (
							1001	; Serial
							3H	; Refresh
							15M	; Retry
							1W	; Expire
							1D	; Minimum TTL
							)

; name server information
@	IN	NS	ops.cluster.test.

; reverse
200	IN	PTR	ops.cluster.test.

; PTR Records for the rest
201	IN	PTR	stack1.cluster.test.
202	IN	PTR	stack2.cluster.test.
203	IN	PTR	stack3.cluster.test.
210	IN	PTR	dev.cluster.test.
```

As long as we're dealing with names:

```
    hostnamectl set-hostname ops.cluster.test
```

The firewall commands are needed - I have no idea why, but I'll guess the < 1024 port.

```
    firewall-cmd --permantent --add-port=53/udp
    firewall-cmd --reload
```

#### OPS ifcfg

If you ran the `buildnet` script, this has been done.

The same change is made to all of the VMs, with just the IPADDR being different: Replace DHCP with a static IP and associated configuration.

I don't know where `enp0s3` came from. The VMs only have one NIC, so edit whatever is there.

```
    $ sudo vi /etc/sysconfig/network-scripts/ifcfg-enp0s3
# BOOTPROTO=dhcp
BOOTPROTO=none
IPADDR=192.168.2.200
PREFIX=24
GATEWAY=192.168.2.1
DNS1=192.168.2.200
DNS2=192.168.2.1
```

The next line should be "DEFROUTE=yes". Leave the rest of the file alone.

And reboot. Be sure you can still connect to the Internet. If you cannot, I have no idea what might be wrong; it just worked for me.

#### ZooKeeper Admin

Everything from here down can be done with:

```
    .~/cluster-test/ops/bin/buildops
```

This is a **terrible** tool, but it exists. If you want it, it is exposed.

See the [official documentation](https://zookeeper.apache.org/doc/r3.6.0/zookeeperAdmin.html#sc_adminserver) for how to use it.

This doesn't work well until the cluster is up because the URLs generate errors.

It is web-based, so open a browser (Firefox comes installed) and bookmark:
- http://zoo1.cluster.test:8081/commands
- http://zoo2.cluster.test:8081/commands
- http://zoo3.cluster.test:8081/commands

Note that the port is configured in cluster-test/stackX/conf/zookeeper.conf as "admin.serverPort" and exposed in the zooup "docker run" command.

#### prettyZoo

Download the rpm from the [github page](https://github.com/vran-dev/PrettyZoo/releases) and install it:

```
    cd ~
    wget https://github.com/vran-dev/PrettyZoo/releases/download/v1.9.4/prettyzoo-1.9.4-1.x86_64.rpm
    sudo rpm -i prettyzoo-1.9.4-1.x86_64.rpm 
```


It does install in an odd directory, so let's start the painful linking process:

```
    ln -s ~/cluster-test/ops/bin/prettyZoo ~/bin/prettyZoo
```

You can configure it now or come back after starting the cluster and use this as verification.

```
    prettyZoo &
```

It likes to write to stderr, so you probably want to open a new terminal tab/window even though it's running in the background.

Adding the ZooKeeper cluster to PrettyZoo:
- Press the New "button" (it's flat).
- Enter zoo1.cluster.test for "host".
- Enter 2181 for "port".
- Press the Save button.
- Repeat for the other two.

Clicking on the name will offer you the option to connect (by pressing the Connect button). 

You may add the servers before bringing them up, if you wish; obviosly connecting to them will not work.

Note that the port is configured in cluster.dev/stackX/conf/zookeeper.conf as "clientPort" and exposed in the zooup "docker run" command.

#### BookKeeper Admin

This doesn't work very well until the BookKeeper is up because the URLs generate errors.

This is web-based. Open a browser (Firefox comes installed) and bookmark:
- http://bookie1.cluster.test:8082/metrics
- http://bookie2.cluster.test:8082/metrics
- http://bookie3.cluster.test:8082/metrics

There are other URLs. See the [Admin REST API](https://bookkeeper.apache.org/docs/4.11.1/admin/http/) for details.

Note that the port is configured in cluster-test/stackX/conf/bookkeeper.conf as BOTH "prometheusStatsHttpPort" and "httpServerPort" and exposed in the bookup "docker run" command.

#### Puslar Manager

Do NOT run this until the cluster is up. It writes bad data that requires wiping everything. After the cluster is up, then:

[Pulsar Manager](https://github.com/apache/pulsar-manager) supposedly can run in a container, but the configuration is not well documented. I haven't gotten there, yet.

Way down at the bottom of the [Apache Pulsar Downloads](https://pulsar.apache.org/en/download/) page, there's a tarball. You do **not** want to wget that. Follow the instructions on the Pulsar Manager page.

```
    wget https://dist.apache.org/repos/dist/release/pulsar/pulsar-manager/pulsar-manager-0.2.0/apache-pulsar-manager-0.2.0-bin.tar.gz
    tar -zxvf apache-pulsar-manager-0.2.0-bin.tar.gz
    cd pulsar-manager
    tar -xvf pulsar-manager.tar
    cd pulsar-manager
    cp -r ../dist ui
    cp ~/cluster-test/ops/conf/application.parameters .
```

#### Prometheus

This runs in Docker, so there is nothing to configure, but we need directories and links:

```
    mkdir -p ~/cluster-test/ops/prometheus/logs
    mkdir -p ~/cluster-test/ops/prometheus/data
    ln -s ~/cluster-test/ops/bin/prometheusup ~/bin/prometheusup
    ln -s ~/cluster-test/ops/bin/prometheusdown ~/bin/prometheusdown
    ln -s ~/cluster-test/ops/bin/prometheustail ~/bin/prometheustail
```

#### Graphana

This runs in Docker, so there is nothing to configure, but we need directories and links.

There are [configuration instructions](https://grafana.com/docs/grafana/latest/administration/configuration/), if you want details. The [Docker configuration](https://grafana.com/docs/grafana/latest/administration/configure-docker/) is a bit different.


```
    mkdir -p ~/cluster-test/ops/grafana/logs
    mkdir -p ~/cluster-test/ops/grafana/data
    sudo chown -R 65534:65534 ~/cluster-test/ops/grafana
    ln -s ~/cluster-test/ops/bin/grafanaup ~/bin/grafanaup
    ln -s ~/cluster-test/ops/bin/grafanadown ~/bin/grafanadown
    ln -s ~/cluster-test/ops/bin/grafanatail ~/bin/grafanatail
```

The owner and group are nobody and nogroup, but the symbolic versions don't work. I have no idea why Grafan requires this, but it does (or you can run it as root).

The default admin user and password are - what else? - "admin" and "admin"

#### Elasticsearch

#### Kibana

### STACK VMs

Set the hostnames (it's just pretty):

```
    hostnamectl set-hostname stackX.cluster.test
```

#### STACK ifcfg

This is in an isolated script everything else can be scripted *except* this.

If you're feeling lucky (or you're me):

```
    setifcfg
```

or do it by hand:

This is the same change as for the [ops machine](#ops-ifcfg). Be sure to give each VM a unique IP and, if diverging from these instructions, that it matches the DNS zone files.

Reboot and test via ping-by-name.

If something doesn't work, try:

```
    dig ops.cluster.test
```

That will do a name lookup and should supply some helpful information.

The most likely problems are:
- zone file doesn't match ifcfg values
- a typo somewhere; check VERY closely.

#### directories and links

This is BY FAR easier to do via script:

```
    buildstack
```

It's so much easier, that I'm not going to type it all out.

The script does two things: Directory permissions and symbolic links.

**Directory Permissions**
Docker does weird things with root and directory ownership. Everything was "clean" when pushed into git, but just in case (and to have it handy for copy/paste if things need to be fixed, later):

```
    chgrp -R docker cluster-test/stack1/node_exporter
    chgrp -R docker cluster-test/stack1/zookeeper
    chgrp -R docker cluster-test/stack1/bookkeeper
    chgrp -R docker cluster-test/stack1/broker
    chgrp -R docker cluster-test/stack1/cassandra
    chmod -R g+w cluster-test
```

Repeat for stack2 and stack3.

**Symbolic Links**

There are scripts for each node. We need to put them somewhere useful.


```
    ln -s ~/cluster-test/stack1/bin/* ~/bin
```

Repeat for stack2 and stack3.

### DEV VM

#### DEV ifcfg

#### github

Install [gh](https://github.com/cli/cli/blob/trunk/docs/install_linux.md)

```
    sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
    sudo dnf install gh 
```

Set the authentication configuration (assuming you'll use it)

```
    gh auth login
```
The user interface is awful. Use the up and down arrows and don't type much, even if you think you should.

If you need a token, follow the [instructions to create one](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token). Save it somewhere. I found out on rebuild that they cannot be retrieved.

Set the username and email:

```
    git config --global user.name "Your Name"
    git config --global user.email you@example.com
```

The pull preference is best set per-repo, but it should be set (so git doesn't nag you):

```
    cd ~/cluster-test
    git config pull.ff only
```


[Prev](cluster-test-03CopyVMs.md)       [Table of Contents](#table-of-contents)     [Next](cluster-test-05FiringItUp.md)
