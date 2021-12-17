# cluster-dev

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
1. [VirtualBox](cluster.dev-01VirtualBoxTempateVM.md)
1. [CentOS](cluster.dev-02CentOSTemplateVM.md)
1. [Copying the VM](cluster.dev-03CopyVMs.md)
1. [VM customization](cluster.dev-04Customization.md)
1. [Firing it all up](cluster.dev-05FiringItUp.md)
1. [Recovering from Mistakes](cluster.dev-06Recovery.md)
1. [Testing Failure Modes](cluster.dev-07Testing.md)

## Introduction {#Introduction}

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

## System Requirements {#Requirements}

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
