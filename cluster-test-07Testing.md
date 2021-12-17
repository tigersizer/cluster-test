# cluster-test: Testing Failure Modes

## Table of Contents {#toc}

1. [Introduction](README.md)
1. [VirtualBox](cluster-test-01VirtualBoxTemplateVM.md) - template VM creation
1. [CentOS](cluster-test-02CentOSTemplateVM.md) - template VM configuration
1. [Copying the VM](cluster-test-03CopyVMs.md)
1. [VM customization](cluster-test-04Customization.md)
1. [Firing it all up](cluster-test-05FiringItUp.md)
1. [Recovering from Mistakes](cluster-test-06Recovery.md)
1. [Testing Failure Modes](#testing-failure-modes)

## Testing Failure Modes

That is one of the points of this elaborate setup. 

All of the "up" commands have matching "down" commands:
- `stackdown` will bring down all the services on the node.
- `zoodown` will `docker stop` the ZooKeeper service on the node on which it is run.
- `bookiedown` the same with the BookKeeper service.
- `brokerdown` the same with the Pulsar Broker service.
- `cassdown` the same with the Cassandra node.
- `proxydown` exists primarily for completeness.



