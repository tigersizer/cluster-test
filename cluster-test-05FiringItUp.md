# cluster-test: Firing It Up

## Table of Contents

1. [Introduction](README.md)
1. [VirtualBox](cluster-test-01VirtualBoxTemplateVM.md) - template VM creation
1. [CentOS](cluster-test-02CentOSTemplateVM.md) - template VM configuration
1. [Copying the VM](cluster-test-03CopyVMs.md)
1. [VM customization](cluster-test-04Customization.md)
1. [Firing It Up](#firing-it-up)
    1. [STACK VMs](#stack-VMs)
        1. [docker-compose](#docker-compose)
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

#### docker-compose

If you use the `docker-compose` method, the entire stack will start at once and write log files.
The OPS VM will deal with logs, if they are generated. 

```
    $ stackup
```

That's it. Do it on each cluster node.

Note that this method does not require a GUI. This can be done via putty, if so desired. The server
is installed and active by default, so there is nothing to install or configure.

#### docker run

If you use the `docker run` method, it's a bit longer and the OPS machine will have no logs to gather. 
After each command, open a new window or tab for the next one:

```
    $ zooup
    $ bookieup
    $ brokerup
    $ cassup
```

On one node you will probably want the Pulsar proxy service, so pick one and:

```
    $ proxyup
```

### OPS VM

I have no idea; I haven't created it, yet.

#### prettyZoo

#### Pulsar Manager

#### Prometheus

### DEV VM

The entire point of this machine is that nothing runs on it. You can do whatever you want to it.

Have fun!
