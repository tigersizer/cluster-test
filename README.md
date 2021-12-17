# cluster-test: Overview

This is a full set of instructions for installing and running five virtual machines:
- Host OS: Windows 10 (although I don't think there is anything Windows-specific in here)
- Guest OS: CentOS 8.5
- VirtualBox as the VM manager
- Three VM nodes for Puslar and Cassandra clusters using Docker
- An operations VM to monitor the clusters with BLEK (Beats, Logstash, Elasticsearch, Kibana), Prometheus, and Grafana
- A development VM in which to use it all

There is a lot of manual setup work before the included scripts will function.

## Table of Contents {#toc}

There is a lot of manual, mostly command-line, work. But it's all simple, short, and copy/paste. So much for the Docker promises.

1. [Introduction](#Introduction)
1. [System Requirements](#Requirements)
1. [Design](#Design)
1. [VirtualBox](cluster-test-01VirtualBoxTemplateVM.md)
1. [CentOS](cluster-test-02CentOSTemplateVM.md)
1. [Copying the VM](cluster-test-03CopyVMs.md)
1. [VM customization](cluster-test-04Customization.md)
1. [Firing it all up](cluster-test-05FiringItUp.md)
1. [Recovering from Mistakes](cluster-test-06Recovery.md)
1. [Testing Failure Modes](cluster-test-07Testing.md)

## Introduction{#Introduction}

This is very long document. Feel free to skip the sections you do not need.

However, from what I've seen, this is not at all normal. Skipping sections may break things, later.

Read the [System Requirements](#Requirements) section to see if the configuration
defined here is compatible with your needs and resources. It may very well not be.

I had a very difficult time making this work, so I thought I'd write it all down in one place 
to save other people the trouble (and to be able to recreate what I had done). Where I made
notes, I am including the links. This does not imply an endorsement on my part or theirs, but 
rather the giving of credit to those who helped me, unknowingly.

I purposefully did not use Docker Swarm or Kubernetes for this because of the amount of 
customization required to get the virtual machines functional. I wouldn't hold my breath, but a
follow-up for Kubernetes seems likely.

Most of this can be done via putty, which comes configured. I assume a GUI per VM with the
full CentOS installation, which includes Gnome, but the cluster nodes could be headless.

## System Requirements{#Requirements}

**A big host machine**

We will be running ZooKeeper, BookKeeper, Pulsar, and Cassandra on each node.
The ops and dev VMs can be smaller, but they're still not tiny.

The total configuration is 16 CPUs, 32GB RAM, and 400GB disk (SSD preferrably).
- 3 cluster VMs of 4 CPU, 8GB, 100GB.
- 2 support VMs of 2 CPU, 4GB, 50GB.

Doubling that won't hurt anything - and the host machine still needs to function.

**A network you control**

By far the easiest way to do this will collide with DHCP and DNS unless you have
at least some control over both.

This will create VMs that appear "flat" to the rest of the network; they are in the
same subnet as all the non-VM things that are part of the netowrk.

There are other options, but this is simplest to use. None of those other options are
in this document.

**Windows 10 Home**

I chose VirtualBox because Windows 10 Home edition does not run Hyper-V.

The same ideas may work elsewhere, since all the configuration is in the virtual machines, but it has not been tested.

## Design{#Design}

This is all software I use at work, but from a very high level. I wanted to understand how it worked in detail and be able to play with it without creating problems for others. I have a beast of a computer that I bought not least out of spite (it's banned in Colorado, from which I had just moved) and I wanted to stretch it a bit. So why not? I figured it would be a weekend project. Hah! It turns out that lots of people do parts of this, but no one (internet-search-able) has done it all. I was taking copious notes and had many links to other helpful people, so why not publicize the result?

That result is five virtual machines:

The three cluster VMs look the same, but with numbers. 
- "stack" is used when refering to the entire machine. In many places I refer to "stackX", which means stack1, stack2, and stack3. 

The software names are much the same:
- zoo1, zoo2, and zoo3 are the ZooKeeper instances.
- bookie1, bookie2, and bookie3 are the BookKeeper instances.
- broker1, broker2, and broker3 are the Puslar Broker instances.
- cass1, cass2, and cass3 are the Cassandra instance.

You can manage them as individual processes or a single block (per VM). 

The Ops VM is quite different than the cluster VMs. It runs:
- DNS to create all of the machine and instance names (e.g. broker2.cluster.test).
- Prometheus and Grapha for metrics.
- Elasticsearch and Kibana for analysis.

The Dev VM is barely defined. It is yours to play with.

The .md files have excruciating amounts of detail on how to set everything up, starting from nothing. One should be able to follow these instructions knowing very little about Linux and nothing about the software being installed - because that's how I started.

If you want to cheat, there are "build" scripts for each machine that just do it all in one fell swoop. Albeit asking lots of questions along the way (mostly answered "Y").

**WARNING:** Doing it that way is *very* dangerous. You may end up with broken networking and no way to access the internet for help fixing it. More likely, you will just need to rebuild the VM(s). But, if you foolishly decide that the host OS will play the Ops VM role, the danger is real.

All of the instructions are in this directory's .md files. The VM-specific directories' README.md files explain what files are there and why - but no instructions.
