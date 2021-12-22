# cluster-test: Copying the Template VM

## Table of Contents

1. [Introduction](README.md)
1. [VirtualBox](cluster-test-01VirtualBoxTemplateVM.md) - template VM creation
1. [CentOS](cluster-test-02CentOSTemplateVM.md) - template VM configuration
1. [Copying the VM](#copying-the-vm)
1. [VM customization](cluster-test-04Customization.md)
1. [Firing it all up](cluster-test-05FiringItUp.md)
1. [Recovering from Mistakes](cluster-test-06Recovery.md)
1. [Testing Failure Modes](cluster-test-07Testing.md)

## Copying the VM

If the VM is still running from the previous step, shut it down. There is a power icon under the down arrow icon in the upper right corner.

This is very simple:
- Right click on the original (CentOS-OPS for me)
- Choose the Clone option.
- Set the Name (e.g. CentOS-Stack1).
- Everything else should be fine.
    - Path: is the same as the original.
    - MAC Address Policy: We're not using NAT but that option works.
    - Additional Options are unchecked.
- Press Next.
- The default of Full Clone is correct.
- Press Clone.

That's it. Now do it three more times (Stack2, Stack3, and DEV).

**Some tweaks**

The OPS machine doesn't need 12GB of RAM or 4 CPUs.
- Select it.
- Press Settings.
- Pick the Motherboard tab.
- Reduce the memory to 8192 (it is doing all that metric work)
- Pick the Processor tab.
- Reduce it to 2 CPUs.

Do the same thing with the DEV machine, but set it to 4GB of RAM (unless you writing large programs).

Start them all up and let's customize the OSes! 
(You can do it one-by-one, but if they can't all run at once, this whole effort is in vain.)

[Prev](cluster-test-02CentOSTemplateVM.md)        [Table of Contents](#table-of-contents)     [Next](cluster-test-04Customization.md)

