# cluster-test: Copying the Template VM

## Table of Contents

1. [Introduction](README.md)
1. [VirtualBox](cluster-test-01VirtualBoxTemplateVM.md) - template VM creation
1. [CentOS](cluster-test-02CentOSTemplateVM.md) - template VM configuration
1. [Copying the VM](#copying-the-vm)
    1. [The Actual Copy](#copying-the-vm)
    1. [Per-Machine Tweaks](#cpu-and-ram)
    1. [Shared Folders](#shared-folders)
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

## CPU and RAM

The OPS machine doesn't need 12GB RAM or 4 CPUs.
- Select it.
- Press Settings.
- Pick the Motherboard tab.
- Reduce the memory to 10240 (it is doing all that metric work)
- Pick the Processor tab.
- Reduce it to 2 CPUs.

Do the same thing with the DEV machine, but set it to 4GB of RAM (unless you writing large programs or using Eclipse - it's a hog!).

## Shared Folders

A directory shared with the host can be useful; I've only used it on DEV.
- Select the VM.
- Press Settings.
- Pick the Shared Folders tab.
- Press the blue folder with the plus icon.
- Select a host Folder Path (e.g. C:\VirtualMachineShares)
- Enter a Folder Name (e.g. DEV)
- Check auto-mount
- Enter a mount point (e.g. /host)
- Check Make Permanent

You need to do one more thing to make this work:

*On the Virtual Machine:* sudo usermod -aG vboxfs ctest

Otherwise you will not have write permission and will need to "sudo" any writes. I tried changing ownership, but it doesn't stick between reboots.

These shared folders don't play well with Docker. You can _try_ adding `-e PGID:` for the vboxsf gid, but it's iffy whether it will work or not. The reason they don't play well: the owner is 'root', the group is 'vboxsf', and the mode is 0770 (rwxrwx---). You cannot change any of that. VirtualBox will not let you. Sometimes this is OK; sometimes it's not. There are tons of articles about Docker and file system permissions; they're mostly about dealing with when creating your own images, not using existing images.

## Start Them!

Start them all up and let's customize the OSes! 
(You can do it one-by-one, but if they can't all run at once, this whole effort is in vain.)

[Prev](cluster-test-02CentOSTemplateVM.md)        [Table of Contents](#table-of-contents)     [Next](cluster-test-04Customization.md)

