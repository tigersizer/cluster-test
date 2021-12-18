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

If you are configuring everything **EXACATLY** as described here, you can get all this done with one command (you did the chmod +x commands in the [common git setup](cluster-test-02-CentOSTempateVM.md#CentOS-git), right?)

**WARNING**: This is not idempotent. Do not run it more than once. 

**WARNING**: This will create *exactly* what's documented here - particularly IP addresses, but also including some of my settings that are *not* expected to be configured here because the NIC configuration is copied in full. If you break networking, it's painful to get it restored - and you're on your own without Internet assistance.

```
    ~/cluster-test/ops/bin/buildops
```

#### BIND

You want to do this BEFORE changing your network configuration because it requires access to the Internet and changing your network configuration may break that.


This is almost word-for-word of a [fedingo post](https://fedingo.com/how-to-configure-dns-server-on-centos-rhel/) on installing BIND.

```
    sudo dnf install bind bind-utils
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
pulsar1	IN	A	192.168.2.201
cass1	IN	A	192.168.2.201
stack2	IN	A 	192.168.2.202
zoo2	IN	A	192.168.2.202
bookie2	IN	A	192.168.2.202
broker2	IN	A	192.168.2.202
pulsar2	IN	A	192.168.2.201
cass2	IN	A	192.168.2.202
stack3	IN	A 	192.168.2.203
zoo3	IN	A	192.168.2.203
bookie3	IN	A	192.168.2.203
broker3	IN	A	192.168.2.203
pulsar3	IN	A	192.168.2.201
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
    $ hostnamectl set-hostname ops.cluster.test
```

The firewall commands at the link are not needed because the firewall is not enabled.

#### OPS ifcfg

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

This is a **terrible** tool, but it exists so if you want it, it is exposed.

See the [official documentation](https://zookeeper.apache.org/doc/r3.6.0/zookeeperAdmin.html#sc_adminserver) for how to use it.

It is web-based, so open a browser (FireFix comes installed) and bookmark:
- http://zoo1.cluster.test:8081/commands
- http://zoo2.cluster.test:8081/commands
- http://zoo3.cluster.test:8081/commands

Note that the port is configured in cluster.dev/stackX/conf/zookeeper.conf as "admin.serverPort" and exposed in the zooup "docker run" command.

#### prettyZoo

Download the rpm from the [github page](https://github.com/vran-dev/PrettyZoo/releases) and install it:

```
    wget https://github.com/vran-dev/PrettyZoo/releases/download/v1.9.4/prettyzoo-1.9.4-1.x86_64.rpm
    sudo rpm -i prettyzoo-1.9.4-1.x86_64.rpm 
```


It does install in an odd directory, so this is as good a place as any for this step:

```
    ln -s ~/cluster-test/ops/bin/* ~/bin
    chmod +x ~/bin/*
```

You can configure it now or come back after starting the cluster and use this as verification.

```
    prettyZoo &
```

It likes to write to stderr, so you probably want to open a new terminal tab/window even though it's running in the background.

Adding the ZooKeeper cluster to PrettyZoo:
- Press the New "button" (it's flat).
- Enter zoo1.cluster.dev for "host".
- Enter 2181 for "port".
- Press the Save button.
- Repeat for the other two.

Clicking on the name will offer you the option to connect (by pressing the Connect button). 

You may add the servers before bringing them up, if you wish; obviosly connecting to them will not work.

Note that the port is configured in cluster.dev/stackX/conf/zookeeper.conf as "clientPort" and exposed in the zooup "docker run" command.

#### BookKeeper Admin

This is web-based. Open a browser (Firefox comes installed) and bookmark:
- http://bookie1.cluster.test:8082/metrics
- http://bookie2.cluster.test:8082/metrics
- http://bookie3.cluster.test:8082/metrics

There are other URLs. See the [Admin REST API](https://bookkeeper.apache.org/docs/4.11.1/admin/http/) for details.

Note that the port is configured in cluster.dev/stackX/conf/bookkeeper.conf as BOTH "prometheusStatsHttpPort" and "httpServerPort" and exposed in the bookup "docker run" command.

#### Puslar Manager

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

This runs in Docker, so there is no thing to configure, but we need directories and links.

There are [configuration instructions](https://grafana.com/docs/grafana/latest/administration/configuration/), if you want details. The [Docker configuration](https://grafana.com/docs/grafana/latest/administration/configure-docker/) is a bit different.


Grafana has some funky user stuff going on; I just punted:

```
    mkdir -p ~/cluster-test/ops/grafana/logs
    mkdir -p ~/cluster-test/ops/grafana/data
    chmod -R a+w ~/cluster-test/ops/grafana 
    ln -s ~/cluster-test/ops/bin/grafanaup ~/bin/grafanaup
    ln -s ~/cluster-test/ops/bin/grafanadown ~/bin/grafanadown
    ln -s ~/cluster-test/ops/bin/grafanatail ~/bin/grafanatail
```

The default admin user and password are - what else? - "admin" and "admin"

#### Elasticsearch

#### Kibana

### STACK VMs

#### STACK ifcfg

This is the same change as for the [ops machine](#ops-ifcfg). Be sure to give each VM a unique IP and, if diverging from these instructions, that it matches the DNS zone files.

Reboot and test via ping-by-name.

If something doesn't work, try:

```
    dig ops.cluster.dev
```

That will do a name lookup and should supply some helpful information.

The most likely problems are:
- zone file doesn't match ifcfg values
- a typo somewhere; check VERY closely.

#### directory permissions

Docker does weird things with root and directory ownership. Everything was "clean" when pushed into git, but just in case:

Remember "stack" is your login; if you used something different, change the ownership appropriately.

```
    sudo chown -R stack cluster-test
    chgrp -R docker cluster-test
    chmod -R g+w cluster-test
```

That's a bit excessive, but it's the least typing.

#### script locations

There are scripts for each node. We need to put them somewhere useful.

Replace "stack1" with the appropriate value.

```
    ln -s ~/cluster-test/stack1/bin/* ~/bin
    chmod +x ~/bin/*
```

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

If you need a token, follow the [instructions to create one](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token).

