# cluster-dev

This is a full set of instructions for installing and running five virtual machines:
- Host OS: Windows 10 (although I don't think there is anything Windows-specific in here)
- Guest OS: CentOS 8.5
- VirtualBox as the VM manager
- Three VM nodes for Puslar and Cassandra clusters using Docker
- An operations VM to monitor the clusters
- A development VM in which to use it all

There is a lot of manual setup work before the included scripts will function.

## Table of Contents {#toc}

This is all manual, mostly command-line, work. But it's all simple, short, and copy/paste.

1. [Introduction](#Introduction)
1. [System Requirements](#Requirements)
1. [VirtualBox](#VirtualBox)
    1. [Networking](#VirtualBox-networking)
    1. [VM Settings](#VirtualBox-VMs)
1. [CentOS](#CentOS)
    1. [Installer](#CentOS-installer)
    1. [Basic Setup](#CentOS-setup)
        1. [sudo](#CentOS-sudo)
        1. [VirtualBox Guest Additions](#CentOS-VBGA)
        1. [DNS](#CentOS-DNS)
        1. [Docker](#CentOS-Docker)
        1. [Eclipse and Java](#CentOS-Eclipse)
        1. [Python](#CentOS-Python)
        1. [vi](#CentOS-vi)
        1. [bash](#CentOS-bash)
        1. [Pulsar and Cassandra](#CentOS-pandc)
        1. [git](#CentOS-git)
1. [Copying the VM](#VirtualBox-copy)
1. [VM customization](#VMs)
    1. [OPS VM](#VMs-ops)
    1. [Cluster Node VMs](#VMs-cluster)
    1. [DEV VM](#VMs-dev)
1. [Firing it all up](#Running)
    1. [Cluster Nodes](#Running-cluster)
        1. [docker-compose](#Running-compose)
        1. [docker run](#Running-run)
    1. [OPS VM](#Running-ops)
        1. [prettyZoo](#Running-prettyzoo)
        1. [Puslar Manager](#Running-pmanager)
    1. [DEV VM](#Running-dev)
1. [Recovering from Mistakes](#Recovering)
1. [Testing Failure Modes](#Testing)

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

## VirtualBox {#VirtualBox}

The Windows Hypervisor does not run on the Home edition of Windows 10. If for some reason you
care, you can read the [installation instructions](https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/quick-start/enable-hyper-v).

There are BIOS settings that must be turned on for virtual machines to work. This is one problem I did not have, so I don't know what they are.

This leads us to [VirtualBox, the Oracle virtual machine manager](https://www.virtualbox.org/). It works just fine for me. Click on the Download link and install it. This is the only required Windows software.

There is one "trick", which we will get to, that makes it work *well*: The Guest Additions. This makes the VM window a seamless part of your host desktop.

### VirtualBox Networking {#VirtualBox-networking}

This is confusing and the manual has an [https://www.virtualbox.org/manual/ch06.html](entire chapter devoted to it).

What matters is how you want connectivity to work. For this, we need all five VMs talking to each other. It's also pretty much mandatory to have a VM to Internet connection for installations. Having access to the VM services from the host Windows machine is not as handy as it may sound, but from a laptop can be convenient.

This means "Bridged Network".

There are options for how you integrate the VMs into the rest of your network. Mine is a home network with a WiFi router (behind a firewall) that handles DHCP and normal DNS. I wanted the VMs to appear "flat" in the network just as if they were separate computers. This allows me to access them from a laptop, as well (or my phone, for that matter).

VirtualBox has a DHCP server. Don't use it. Not having that causes the VMs to look "upstream" to the router's DHCP. DHCP and cluster configuration do not play well together, at all. There is no magic DHCP/DNS connector and hard-coding IPs is doomed to failure.

Therefore, I chopped the class C (I know, it's not called that these days) address space in half. My router handles DHCP from .2 to .127 and the rest are mine to hard-code into VMs.

These instructions will create five VMs with static IP addresses and domain-name lookup in the same subnet as the rest of the network.

This will not play well with corporate networks.

### Virtual Box VM Settings {#VirtualBox-VMs}

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

## CentOS {#CentOS}
Find a CentOS ISO and download it (this is the last Windows download). 
[CentOS.org](https://www.centos.org/download/) is a logical place to find the CentOS ISOs.

If this isn't going to be your only VM set, I recommend creating a VMISO folder somewhere (HDD storage is fine) so they're all in one convenient place.

Go back to Virtual Box and "mount" this ISO in the Storage settings.

Start the VM.

### CentOS Installer {#CentOS-installer}

You will notice that the VM window captures your mouse once you click in it. The right ctrl key will release that capture. We'll fix that inconvenience, shortly.

The installer pretty much "just works".
- Click on all the required things (they have red text under the icons) and do what it asks.
- Create your user. This can be done later, but why not do it from the start? The rest of this document calls that user *stack*.
- Turn on the network. This is not entirely obvious. In the network setup, there is an on/off slider that defaults to off. Slide it "on". 
This will connect to the DHCP server and assign you an IP address. We need network access for further installations.

Finish the installer, which will reboot. 

Finish the installation wizard that comes up after you login.

### CentOS Basic Setup {#CentOS-setup}

There are a number of things that are less than ideal about a bare installation. This section describes the things *I* like. Feel free to customize your heart out before we start copying this VM. Everything you do here is one less thing to be done multiple times, later.

After rebooting, login as *stack* and open a terminal window (click Activities in the upper left and select the bottom icon).

You will notice that resizing the VM window doesn't resize what's inside. We'll get to that.

Oh, I assume you know how to use vi. If not, use an editor of your choice; `nano` is popular, but not always installed. vi is always there.

#### sudo {#CentOS-sudo}

This is basically required to do anything. Life is much simpler without having to type a password each time. So, we'll make that happen. After this, you can forget the root password that you just configured (although I don't recommend that).

```
    $ su root
    password:
    $ cd /etc
    $ vi sudoers
```

Find the line that looks like this:

```
    ## Allows people in group wheel to run all commands
    %wheel ALL=(ALL)       ALL
```

Comment that out. Right below it is this:

```
    ## Same thing without a password
    #%wheel  ALL=(ALL)       NOPASSWD: ALL
```

Remove that comment hash character. Write it and quit.

One last step (still as root):

```
    $ usermod -aG wheel stack
```

*stack* is the user you are logged in as.

It's probably unnecessary to actually reboot, but rebooting works. Either use the CentOS power/restart or `reboot` while you're still root.

Note that this step may break some corporate policy or another. Passwordless root access freaks some people out (and it's not terribly wise, but these are development VMs).

#### VirtualBox Guest Additions {#CentOS-VBGA}

These are like magic (and why you want so much video memory), but they rebuild parts of the kernel, which means you need to be up-to-date with the kernel building tools, which the ISO is not.

These instructions are an amalgam of a [RedHat discussion](https://access.redhat.com/discussions/4452161) and a 
[TecMint article](https://www.tecmint.com/install-virtualbox-guest-additions-on-centos-8/). If you want to go the hard way, try installing it (instructions below) and when it doesn't work, check `/var/log/vboxadd-install.log` for the errors.

This is not a fast process, depending on your download speeds. If you want to walk away, use `yum -y` so it doesn't wait for you type "y".

```
    $ sudo yum groupinstall "Development Tools"
    $ sudo yum kernel-devel elfutils-libelf-devel
```

That's from the RedHat discussion and doesn't help much, but it downloads lots of stuff you need, anyway.
To finish it off:

```
    $ sudo dnf install epl-release
```

You want these two things to match:

```
    $ rpm -q kernel-devel
    kernel-devel-4.18.0-348.2.1.el8_5.x86_64
    $ uname -r
    4.18.0-348.2.1.el8_5.x86_64    
```

Those do, but I've done this already. If they do, great, skip this step:

```
    $ sudo dnf update kernel-*
    $ sudo reboot
```

Now they will match. If they do not, I have no idea what to do.

BTW: There is very little difference between [yum and dnf](https://embeddedinventor.com/yum-dnf-explained-for-beginners/).  I just followed the Internet instructions and didn't try to unify them.

Finally, we can install the Guest Additions:
- Click on the Device menu (of the VM window, which requires releasing mouse capture).
- Choose the last option: "Insert Guest Additions CD".
- If it asks "are you sure you want to run this?", click the Run button.

It will do some kernel rebuilding and reboot. There are now three choices in the boot menu; the new, first one should auto-select and boot.

The mouse will now move seamlessly. Resizing the VM window will resize the Desktop. Clipboard works between host and guests.
- shift-ctrl-C will copy, but it must be the left shift and ctrl keys.
- shift-ctrl-V will paste, but it must be the left shift and ctrl keys.

This is confusing and do not paste into vi unless you're in insert mode!

See why we do this *before* copying the VM?

#### DNS {#CentOS-DNS}

We only want a DNS server on the operations VM, so we don't want to do that, yet. 

Each VM will have its own ifconf, so we don't want to do that, yet, either.

However, it's worth spending some time thinking about names. These instructions will create a `cluster.dev` zone and the following names:
- ops
- stack1
    - zoo1
    - bookie1
    - broker1
    - cass1
- stack2
    - zoo2
    - bookie2
    - broker2
    - cass2
- stack3
    - zoo3
    - bookie3
    - broker3
    - cass3
- dev

The five IPs will be 192.168.2.201, .202, .203, 204, and .205.

You do not need to do that. In fact, it is unlikely that your network, which we are **not** routing to but a part of, is using the 192.168.2.0/24 address space (aka class C network).

If you want to create a separate address space and routing, you're on your own. The DNS setup should work, though.

#### Docker {#CentOS-Docker}

You want Docker on all the VMs. There is a "trick": It collides with podman, which is a CentOS container thing. So, get rid of that:

```
    $ sudu yum erase podman buildah
```

Docker has [CentOS intallation instructions](https://docs.docker.com/engine/install/centos/); I copied them here:

```
    $ sudo yum install -y yum-utils
    $ sudo yum-config-manager \
        --add-repo \
        https://download.docker.com/linux/centos/docker-ce.repo
    $ sudo yum install docker-ce docker-ce-cli containerd.io
    $ sudo systemctl start docker
```

Of course, we're not done. This [post-intallation](https://docs.docker.com/engine/install/linux-postinstall/) makes it work properly:

```
    $ sudo groupadd docker
    (I got 'already exists')
    $ sudo usermod -aG docker $USER
    (must logout/in for this to take effect)
    $ sudo systemctl enable docker.service
    $ sudo systemctl enable containerd.service
```

Docker will now start on boot. We don't need it, now, so no need to reboot or start it manually:

```
    $ sudo systemctl start docker 
```

But you can do either if you want to test it, which is probably wise:

```
    $ docker run hello-world
```

It prints a lot more than "hello word".

As long as we're here, we might as well get `docker-compose`

```
    $ sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    $ sudo chmod +x /usr/local/bin/docker-compose
```

Presumably, that version in the URL will change over time.

#### Eclipse {#CentOS-Eclipse}

This is not required. In fact, I haven't even used it, yet. But it's handy for Python and an up-to-date Java is usually a good thing.

Java first. The current version is 11 and the CentOS distribution comes with 1.8.

```
    $ sudo yum -y install java-11-openjdk-devel
    $ sudo alternatives --config java
```

The `alternatives` command will ask which one you want to be the default; pick the one you just installed.

Then Eclipse (do not `sudo` this one; just install it for yourself):

```
    $ wget http://ftp.yz.yamagata-u.ac.jp/pub/eclipse/oomph/epp/2021-09/R/eclipse-inst-linux64.tar.gz
    $ tar xvf eclipse-inst-linux64.tar.gz
    $ cd eclipse-installer/
    $ ./eclipse-inst
```

When it asks to launch Eclipse, say yes or it yells at you.

As long as you have Eclipse open...

#### Python {#CentOS-Python}

Do NOT install Python 2.x unless the world is coming to an end. Trying to manage both Python 2.x and Python 3.x is a nightmare.

We want to be sure that Python 3 is the default:

```
    $ sudo alternatives --config python
```

You shouldn't have a choice, but choosing the only option (Python 3) will make "python" run that one.

While you have Eclipse open, install the PyDev Python plugin from the Marketplace.

#### vi / VIM {#CentOS-vi}

I'm on the "space" side of the tab/space war, so I configure vi (and Eclipse) to use spaces. Create a .vimrc file and insert:

```
    filetype plugin indent on
    " On pressing tab, insert spaces
    set expandtab
    " set tab indent
    set tabstop=4
    set softtabstop=4
    " when indenting with '>' use 2 spaces
    set shiftwidth=4
    set autoindent
    set smarttab
```

One of those annoys me on insert, but I don't know which one it is.

Oddly enough, logout/login doesn't seem to force this to work; I rebooted.

#### bash {#CentOS-bash}

I use separate terminal windows or tabs for Docker containers and I like having them titled. This is handy - and it was ridiculously difficult to find a version that actually worked, so I saved it.

Open .bashrc and append:

```
    function set-title() {
      if [[ -z "$ORIG" ]]; then
        ORIG=$PS1
      fi
      TITLE="\[\e]2;$@\a\]"
      PS1=${ORIG}${TITLE}
    }
    function title { echo -en "\033]2;$1\007"; }
```

If you think this is silly, feel free to remove the "title" lines from the "up" commands, which we will discuss later.

#### Pulsar and Cassandra {#CentOS-pandc}

You don't need to install these. They will be run in Docker containers, not "natively" in the VM.

It's a bit of a wash, since Docker will just magically do it when required, but you can pre-pull the images:

```
    $ docker pull apachepulsar/pulsar:2.8.1
    $ docker pull cassandra:3.11
```

The scripts use those versions; feel free to pick different ones (and make the necessary changes)

#### git {#CentOS-git}

Can't forget to clone this repository! It's not all typing. There are scripts and configurations and things!

```
    $ git clone 
```

## Copying the VM {#VirtualBox-copy}

## VM Customization {#VMs}

Each virtual machine is slightly different (notably the IP addresses).

### OPS VM {#VMs-ops}

We'll do this one first so it's ready to deal with DNS right away. That is the only "do this first" step, here. If you want to hurry and get the cluster up before you can monitor it - I get it. Skip ahead and come back to this step.

#### ifcfg-enp0s3

#### DNS 

#### prettyZoo

#### Puslar Manager

#### Prometheus

#### Graphana

#### Kibana

### Cluster Node VMs {#VMs-cluster}

#### ifcfg-enp0s3

#### script locations

There are scripts for each node. We need to put them somewhere useful.

Replace "stack1" with the appropriate value.

```
    $ cp ~/cluster/stack1/bin/* ~/bin
    $ chmod +x ~/bin/*
```

### DEV VM {#VMs-dev}

## Firing it all up {#Running}

There are two ways to do this: Fire up the whole stack with logs 
or bring up each service in its own window/tab and let the logs scroll.

### Cluster Nodes {#Running-cluster}

If you're not logged into all the cluster nodes, do so.

#### docker-compose {#Running-compose}

If you use the `docker-compose` method, the entire stack will start at once and write log files.
The OPS VM will deal with logs, if they are generated. 

```
    $ stackup
```

That's it. Do it on each cluster node.

Note that this method does not require a GUI. This can be done via putty, if so desired. The server
is installed and active by default, so there is nothing to install or configure.

#### docker run {#Running-run}

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

### OPS VM {#Running-ops}

I have no idea; I haven't created it, yet.

#### prettyZoo {#Running-prettyzoo}

### DEV VM {#Running-dev}

The entire point of this machine is that nothing runs on it. You can do whatever you want to it.

Have fun!

## Recovering from Mistakes {#Recovering}

This can be difficult because the entire point of all this clustering is redundancy. 

If you need to start from scratch after running bookies, you will need to wipe the ZooKeeper data, which will
require starting Pulsar from scratch, too.

Cassandra also likes its redundancy and bringing the cluster up and down moves a lot of data. If you're doing
Cassandra work, I recommend leaving it running and putting the host to "sleep" rather than powering it down.

## Testing Failure Modes {#Testing}

That is one of the points of this elaborate setup. 

All of the "up" commands have matching "down" commands:
- `stackdown` will bring down all the services on the node.
- `zoodown` will `docker stop` the ZooKeeper service on the node on which it is run.
- `bookiedown` the same with the BookKeeper service.
- `brokerdown` the same with the Pulsar Broker service.
- `cassdown` the same with the Cassandra node.
- `proxydown` exists primarily for completeness.



