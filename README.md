# cluster-test: Overview

This is a full set of instructions for installing and running five virtual machines:
- Host OS: Windows 10 (although I don't think there is anything Windows-specific in here)
- Guest OS: CentOS 8.5
- VirtualBox as the VM manager
- Three VM nodes for Puslar and Cassandra clusters using Docker
- An operations VM to monitor the clusters with BLEK (Beats, Logstash, Elasticsearch, Kibana), Prometheus, and Grafana
- A development VM on which to use it all

There is some of manual setup work before the included scripts will function.

## Table of Contents

There is a lot of manual, mostly command-line, work. But it's all simple, short, and copy/paste. So much for the Docker promises.

1. [Introduction](#introduction)
    1. [System Requirements](#system-requirements)
    1. [Design](#design)
    1. [git commits](#git-commits)
1. [VirtualBox](cluster-test-01VirtualBoxTemplateVM.md) - template VM creation
1. [CentOS](cluster-test-02CentOSTemplateVM.md) - template VM configuration
1. [Copying the VM](cluster-test-03CopyVMs.md)
1. [VM customization](cluster-test-04Customization.md)
1. [Firing it all up](cluster-test-05FiringItUp.md)
1. [Recovering from Mistakes](cluster-test-06Recovery.md)
1. [Testing Failure Modes](cluster-test-07Testing.md)

## Introduction

Update on making the repo public: This is presented as-is with nothing implied: warranty, fitness, support, or even sanity.

The .md files are a very long document. Feel free to skip the sections you do not need.

However, from what I've seen, this is not at all normal. Skipping sections may break things, later.

Read the [System Requirements](#system-requirements) section to see if the configuration
defined here is compatible with your needs and resources. It may very well not be.

Most of this can be done via putty, which comes configured. I assume a GUI per VM with the
full CentOS installation, which includes Gnome, but the *stackX* machines could be headless.

## System Requirements

**A big host machine**

We will be running ZooKeeper, BookKeeper, Pulsar, and Cassandra on each node.
The ops and dev VMs can be smaller, but they're still not tiny.

The total configuration is 16 CPUs, 42GB RAM, and 400GB disk (SSD preferrably).
- 3 cluster VMs of 4 CPU, 12GB, 100GB.
- 2 support VMs of 2 CPU, 4GB and 12GB, 50GB/100GB.

I tried to get the OPS machine running in 8GB and it had crazy memory pressure.

And the host machine still needs to function.

Note that sitting idle the cluster VMs consume over 90% of their 12GB. I started with 8GB and it just wasn't enough.

Update: Now that I've got monitoring up (particularly the various memory metrics), I plan to work on reducing the footprint (particularly Cassandra), but it's not pressing because four 12GB VMs fit on my host just fine.

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

## Design

I wanted to understand in detail how "this stuff" worked and be able to play with it without creating problems for others. I have a beast of a computer that I bought, not least out of spite (it's banned in Colorado, from which I had just moved), and I wanted to stretch it a bit. So why not? I figured it would be a weekend project. Hah! It turns out that lots of people do parts of this, but no one (internet-search-able) has done it all. I was taking copious notes and had many links to other helpful people, so why not publicize the result?

I purposefully did not use Docker Swarm or Kubernetes for this because of the amount of customization required to get the virtual machines functional and the lack of documentation. I wouldn't hold my breath, but a follow-up for Kubernetes seems likely.

That result is five virtual machines:

The three cluster VMs look the same, but with numbers. 
- "stack" is used when refering to the entire machine. In many places I refer to "stackX", which means stack1, stack2, and stack3. 

The software names are much the same:
- zoo1, zoo2, and zoo3 are the ZooKeeper instances.
- bookie1, bookie2, and bookie3 are the BookKeeper instances.
- broker1, broker2, and broker3 are the Puslar Broker instances.
- cass1, cass2, and cass3 are the Cassandra instance.

You can manage them as individual components or a single block (per VM). 

The Ops VM is quite different than the cluster VMs. It runs:
- DNS to create all of the machine and instance names (e.g. broker2.cluster.test).
- Prometheus and Grapha for metrics.
- Elasticsearch and Kibana for analysis.

The Dev VM is barely defined with Java and Python. C++ is planned. It is yours to play with.

The .md files have excruciating amounts of detail on how to set everything up, starting from nothing. One should be able to follow these instructions knowing very little about Linux and nothing about the software being installed - because that's how I started. For what's not in the .md files, check the scripts for stack1 (and/or ops).

If you want to cheat, there are "build" scripts for each machine that just do it all in one fell swoop.

**WARNING:** Configuring the network, which has its own set of scripts for isolation, via script is *very* dangerous. You may end up with broken networking and no way to access the internet for help fixing it. More likely, you will just need to rebuild the VM(s). But, if you foolishly decide that the host OS will play the Ops VM role, the danger is real.

All of the instructions are in this directory's .md files. The VM-specific directories' README.md files explain what files are there and why - but no instructions.

### git commits

These look a bit odd because I'm working on all five machines in at the same time. For example, it's handy to edit stack2's buildstack script while actually testing the work on stack1. Or writing the ops documentation on the dev machine while doing the work on the ops machine.

From github, you cannot see this. That makes the commit/push trail a bit confusing to sort out.
