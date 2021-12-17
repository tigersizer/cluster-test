# cluster-test: Setting up the Template Virtual Machine

This is all manual, but it's all simple, short, and copy/paste.

1. [Networking](#VirtualBox-networking)
1. [VM Settings](#VirtualBox-VMs)

## VirtualBox{#VirtualBox}

The Windows Hypervisor does not run on the Home edition of Windows 10. If for some reason you
care, you can read the [installation instructions](https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/quick-start/enable-hyper-v).

There are BIOS settings that must be turned on for virtual machines to work. This is one problem I did not have, so I don't know what they are.

This leads us to [VirtualBox, the Oracle virtual machine manager](https://www.virtualbox.org/). It works just fine for me. Click on the Download link and install it. This is the only required Windows software.

There is one "trick", which we will get to, that makes it work *well*: The Guest Additions. This makes the VM window a seamless part of your host desktop.

### VirtualBox Networking{#VirtualBox-networking}

This is confusing and the manual has an [https://www.virtualbox.org/manual/ch06.html](entire chapter devoted to it).

What matters is how you want connectivity to work. For this, we need all five VMs talking to each other. It's also pretty much mandatory to have a VM to Internet connection for installations. Having access to the VM services from the host Windows machine is not as handy as it may sound, but from a laptop can be convenient.

This means "Bridged Network".

There are options for how you integrate the VMs into the rest of your network. Mine is a home network with a WiFi router (behind a firewall) that handles DHCP and normal DNS. I wanted the VMs to appear "flat" in the network just as if they were separate computers. This allows me to access them from a laptop, as well (or my phone, for that matter).

VirtualBox has a DHCP server. Don't use it. Not having that causes the VMs to look "upstream" to the router's DHCP. DHCP and cluster configuration do not play well together, at all. There is no magic DHCP/DNS connector and hard-coding IPs is doomed to failure.

Therefore, I chopped the class C (I know, it's not called that these days) address space in half. My router handles DHCP from .2 to .127 and the rest are mine to hard-code into VMs.

These instructions will create five VMs with static IP addresses and domain-name lookup in the same subnet as the rest of the network.

This will not play well with corporate networks.

### Virtual Box VM Settings{#VirtualBox-VMs}

These settings are (mostly) changeable at-will. Since we're creating three VMs of one sort and two of another, it makes sense to create the first one as one of the three. That way, when we copy it, we only need to edit two of them.

This is very simple. Press the New button and the first wizard page appears:
- Enter the name. I chose CentOS-S0 for the operations machine, -S1 thru -S3 for the cluster nodes, and -Dev for the dev machine.
It doesn't matter what you pick because the names are not used for anything.
- Enter the Machine Folder. If you haven't done this before, the default is probably fine. You really want an SSD for this.
- Enter the Type (Linux), if necessary. Typing "CentOS" as the beginning of the name set this for me.
- Enter the Version (RedHat 64-bit), if necessary. This also auto-filled for me.
- Press the Next button.

This brings up the Memory Size page, which has a useless slider on it.
- Click in the box and type the desired number (4096 minium, 8192 is good, more is better).
- Press the Next button.

There are four Hard disk pages. In order, you want:
- Select (the default) "Create a virtual hard disk now"; press Create button.
- Select (the default) "VDI (VirtualBox Disk Image)"; press Next button.
- Select (the default) "Dynamically allocated"; press the Next button.
- Another useless slider; click in the box and set it to 100GB; press the Create button.

This ends the creation wizard, but we're not done, yet.

Press the Settings button:
- General settings
    - Advanced tab. Set "Shared Clipboard" to "Bidirectional" (this is just handy)
- System settings
    - Processor tab. This slider is useful. Set the desired number (4 is minimum, 8 is good, more is better).
    - The "Enable Nested VT-x/AMD-V" checkbox allows you to run VMs inside your VMs. We don't need it, but I wondered what it did.
- Display settings
    - Screen tab. Crank up the "Video Memory" to 128MB (slider works fine for this).
    - You're on your own for "Monitor Count"; I have only one.
- Storage settings
    - Select the DVD icon under "Controller IDE", the press the other DVD icon on the right.
    - Pick your OS installation ISO, which we [have not downloaded, yet](#CentOS).
- Network settings:
    - Adapter 1 tab. Select "Bridged Adapter" for "Attached To".

Now it's ready to fire up - except we need the ISO...

