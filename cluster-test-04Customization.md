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
        1. [/usr/local](#-usr-local)
        1. [Python Pulsar Client](#pulsar-client)
        1. [cqlsh](#cqlsh)
        1. [Reading .md files in Firefox](#reading--md-files-locally)
        1. [protobuf compiler](#protobuf)
1. [Firing it all up](cluster-test-05FiringItUp.md)
1. [Recovering from Mistakes](cluster-test-06Recovery.md)
1. [Testing Failure Modes](cluster-test-07Testing.md)

## VM Customization

Each virtual machine is slightly different (notably the IP addresses).

### OPS VM

We'll do this one first so it's ready to deal with DNS right away. That is the only "do this first" step, here. If you want to hurry and get the cluster up before you can monitor it - I get it. Configure bind/named then skip ahead and come back to this step.

There are two scripts for this:
- `setnet` configures BIND/named and the enp0s3 exactly as mine are; you probably want to do these steps manually so you can change things.
- `buildops` does the rest (from ZooKeeper Admin down); this is safe enough that you can just run it - you don't even need to read any of the documentation.

#### BIND

The **dangerous way**, which will reboot at the end:

```
    ~/cluster-test/ops/bin/setnet
```

The **manual way**, which is not exactly "safe", but it's under your control:

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

In the same file, you need to turn recursion on. Most (as in "nearly all, everywhere") DNS clients do not respond well to "go look elsewhere" replies, so this server must do it on their behalf.

Find "recursion: no" and change it to:

```
    recursion yes;
    allow-recursion { any; };
```

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

If you ran the `setnet` script, this has been done.

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

Note that after running for several days, I did lose external connectivity. After searching high and low for the problem, I shut everything down and rebooted the host Windows machine. It all started working, again. There was a Windows Update pending; I do not know if that was related or not.

#### ZooKeeper Admin

Everything from here down can be done with:

```
    ~/cluster-test/ops/bin/buildops
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
    prettyZoo
```

That script titles the window and runs it the foreground because it likes to write to stderr.

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

There are other URLs, but those are handy for testing bookie up-ness and Prometheus configuration. See the [Admin REST API](https://bookkeeper.apache.org/docs/4.11.1/admin/http/) for details.

Note that the port is configured in cluster-test/stackX/conf/bookkeeper.conf as BOTH "prometheusStatsHttpPort" and "httpServerPort" and exposed in the bookup "docker run" command.

#### Puslar Manager

Do NOT run this until the cluster is up. It writes bad data that requires wiping everything. After the cluster is up, then:

It runs in Docker, so the usual shortcuts:

```
    ln -s ~/cluster-test/ops/bin/pmandown ~/bin/pmandown
    ln -s ~/cluster-test/ops/bin/pmantail ~/bin/pmantail
    ln -s ~/cluster-test/ops/bin/pmanup ~/bin/pmanup
```

#### Prometheus

This runs in Docker, so there is nothing to configure, but we need directories and links:

```
    mkdir -p ~/cluster-test/ops/prometheus/logs
    mkdir -p ~/cluster-test/ops/prometheus/data
    chgrp -R docker ~/cluster-test/ops/prometheus
    chown g+w ~/cluster-test/ops/prometheus
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

This also runs in Docker, so we just need the usual, with a bit of [crazy group-ness](https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html), about halfway down the page.

Note that the paths on that page are correct. The ones on the linked "Important Elasticsearch configuration" are not.


```
    mkdir -p ~/cluster-test/ops/elastic/data
    mkdir -p ~/cluster-test/ops/elastic/logs
    chgrp -R 0 ~/cluster-test/ops/elastic
    chmod -R g+rwx ~/cluster-test/ops/elastic
    chgrp -R 0 ~/cluster-test/ops/conf/elasticsearchconfig
    chmod -R g+rwx ~/cluster-test/ops/conf/elasticsearchconfig
    ln -s ~/cluster-test/ops/bin/elasticup ~/bin/elasticup
    ln -s ~/cluster-test/ops/bin/elasticdown ~/bin/elasticdown
    ln -s ~/cluster-test/ops/bin/elastictail ~/bin/elastictail
```

#### Kibana

This also runs in Docker, so we just need the usual:

```
    mkdir -p ~/cluster-test/ops/kibana/data
    mkdir -p ~/cluster-test/ops/kibana/logs
    chgrp -R docker ~/cluster-test/ops/kibana
    chmod -R g+w ~/cluster-test/ops/kibana
    ln -s ~/cluster-test/ops/bin/kibanaup ~/bin/kibanaup
    ln -s ~/cluster-test/ops/bin/kibanadown ~/bin/kibanadown
    ln -s ~/cluster-test/ops/bin/kibanatail ~/bin/kibanatail
```

It complians a **LOT** about security. Perhaps I'll deal with it, later.

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

Repeat on stack1, stack2, and stack3.

It's so much easier, that I'm not going to type it all out.

The script does three things: Create diectories, set directory permissions and create symbolic links in ~/bin.

**Create Directories**
We need directories because we want to:
- persist data between Docker runs
- persist logs during Docker runs for logstash
- the component directories are not node-number decorated
- the log file names are

There are no "stable" files in these directories to put into github.

**Directory Permissions**
Docker does weird things with root and directory ownership. Different images expect different things from their mounted volumes. Generally, "docker" group membership and group write permissions does it. There are some exceptions.

**Symbolic Links**
The up/down/tail commands for each component are the only things that are not decorated with the node number. That is, "zooup" exists for each node, but it does something different. Symbolic links are created in the ~/bin directory so the commands are the same on each node.

See the [stack1 README.md](stack1/README.md) for details.

### DEV VM

As usual, everything except the network configuration can be done via

```
    builddev
```

If you're doing this manually, you can do as little or as much of this as you'd like. Remember, these started out as (and continue to be) notes to myself about how to configure *my* machines. The point is: If I need to do this again next year, I don't fofet what I did; not only "how?" but "what?"

#### DEV ifcfg

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


#### github

Install [gh](https://github.com/cli/cli/blob/trunk/docs/install_linux.md)

```
    sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
    sudo dnf install gh 
```

Set the authentication configuration (assuming you'll use it). This is interactive, so the script does not run it.

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

#### /usr/local

I got tired of sudo-ing to install Python libraries, so I chose the nuclear option:

```
    cd /usr/local
    sudo chown -R ctest *
```

It's my VM; I'll install if I want to.

#### pulsar-client

The Python Package Index has the [Pulsar Client library](https://pypi.org/project/pulsar-client/)

```
    pip3 install pulsar-client
```

#### cqlsh

Install cqlsh - but *not* from DataStax. Currently (Dec 2021), all the internet searches point to one that requires Python 2.7. You do not want Python 2, if you can possibly help it.

The Python Package Index [has cqlsh](https://pypi.org/project/cqlsh/).

Not having version 2, pip and pip3 *should* do the same thing, but pip3 is installed and pip is not, so pip3 it is.

```
    pip3 install -U cqlsh
```

This causes issues with the "describe" command. In 3.11, which is what the cluster is running (unless you changed it), it is a client-side command. In 4.x, which is what the Python 3 cqlsh is, it is a server-side command. 

The "cql" command on the cluster nodes runs locally so the versions always match.

This installs the Python Cassandra driver, too. If you're not installing cqlsh and want the driver:

```
    pip3 install cassandra-driver
```

#### reading .md files locally

The Firefox addon doesn't "just work".

From a [superuser.com post](https://superuser.com/questions/696361/how-to-get-the-markdown-viewer-addon-of-firefox-to-work-on-linux/1175837#1175837):

```
    mkdir -p ~/.local/share/mime/packages
    vi ~/.local/share/mime/packages/text-markdown.xml
        then paste
<?xml version="1.0"?>
<mime-info xmlns='http://www.freedesktop.org/standards/shared-mime-info'>
  <mime-type type="text/plain">
    <glob pattern="*.md"/>
    <glob pattern="*.mkd"/>
    <glob pattern="*.markdown"/>
  </mime-type>
</mime-info>
        then :wq
    update-mime-database ~/.local/share/mime
```

#### protobuf

Start with https://github.com/protocolbuffers/protobuf/releases

The prebuilt binary for the compiler is a "protoc" file at the link.

It unzips into bin and include from where you run this. I decided that, just as I have ~/bin in PATH, I want ~/include in any include path I may need.

```
    cd ~
    wget https://github.com/protocolbuffers/protobuf/releases/download/v3.19.1/protoc-3.19.1-linux-x86_64.zip
    unzip protoc-3.19.1-linux-x86_64.zip
    # cp -r include /usr/local/include
    rm readme.txt
    rm protoc-3.19.1-linux-x86_64.zip
```

I don't know how this is supposed to work, but I couldn't get anything to compile without copying the `descriptor.proto` file into the *local directory* of my .proto files. I should give credit to the link where I found this information, but I didn't make note of it.

```
    cd ~/code/wherever
    cp ~/protobuf-3.19.1/src/google/protobuf/descriptor.proto .
```

Then protoc works. If you put that path in -I, it does not.

```
    protoc -I=. --python_out=. mydefintion.proto
```


    
[Prev](cluster-test-03CopyVMs.md)       [Table of Contents](#table-of-contents)     [Next](cluster-test-05FiringItUp.md)
