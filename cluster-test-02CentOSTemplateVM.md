# cluster-test: Installing and Configuring the Template CentOS

## Table of Contents

1. [Introduction](README.md)
1. [VirtualBox](cluster-test-01VirtualBoxTemplateVM.md) - template VM creation
1. [CentOS](#centos) - template VM configuration
    1. [Installer](#centos-installer)
    1. [Setup](#setup)
    1. [Manual Setup](#centos-manual-setup)
        1. [sudo](#sudo)
        1. [VirtualBox Guest Additions](#virtualbox-guest-additions)
        1. [Script the Rest](#script-the-rest)
    1. [What the script does](#what-the-script-does)
        1. [git](#git)
        1. [Domain Name Server](#domain-name-server)
        1. [Prometheus Node Exporter](#prometheus-node-exporter)
        1. [Firefox](#firefox)
        1. [Docker](#docker)
        1. [Eclipse and Java](#eclipse-and-java)
        1. [Python](#python)
        1. [vi](#vi)
        1. [bash](#bash)
1. [Copying the VM](cluster-test-03CopyVMs.md)
1. [VM customization](cluster-test-04Customization.md)
1. [Firing it all up](cluster-test-05FiringItUp.md)
1. [Recovering from Mistakes](cluster-test-06Recovery.md)
1. [Testing Failure Modes](cluster-test-07Testing.md)

## CentOS

This is all manual, mostly command-line, work. But it's all simple, short, and copy/paste.

Find a CentOS ISO and download it (this is the last Windows download). 
[CentOS.org](https://www.centos.org/download/) is a logical place to find the CentOS ISOs.

If this isn't going to be your only VM set, I recommend creating a VMISO folder somewhere (HDD storage is fine) so they're all in one convenient place.

Go back to Virtual Box and "mount" this ISO in the Storage settings.

Start the VM.

### CentOS Installer

You will notice that the VM window captures your mouse once you click in it. The right ctrl key will release that capture. We'll fix that inconvenience, shortly.

The installer pretty much "just works".
- Click on all the required things (they have red text under the icons) and do what it asks.
- Create your user. This can be done later, but why not do it from the start? The rest of this document calls that user *stack*.
- Turn on the network. This is not entirely obvious. In the network setup, there is an on/off slider that defaults to off. Slide it "on". 
This will connect to the DHCP server and assign you an IP address. We need network access for further installations.

Finish the installer, which will reboot. 

Finish the installation wizard that comes up after you login.

### Setup

There are a number of things that are less than ideal about a bare installation. This section describes the things *I* like. Feel free to customize your heart out before we start copying this VM. Everything you do here is one less thing to be done multiple times, later.

After rebooting, login as *stack* and open a terminal window (click Activities in the upper left and select the bottom icon).

You will notice that resizing the VM window doesn't resize what's inside. We'll get to that.

Oh, I assume you know how to use vi. If not, use an editor of your choice; `nano` is popular, but not always installed. vi is always there.

### Manual Setup

The first few steps must be done manually. After that, you can decide whether or not script the rest.

#### sudo

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

#### VirtualBox Guest Additions

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

#### Script the Rest

If you are going to build **EXACTLY** my configuration, the rest of the setup below can be accomplished in one step:

```
    $ cluster-test/common/bin/buildcommon
```

These "build" scripts are very dangerous to run:
- They are *NOT* idempotent. Run them only once.
- They create *EXCATLY* what is documented, here. If you want *anything* different, run them at your own risk.

### What the script does

#### git

Can't forget to clone this repository! It's not all typing. There are scripts and configurations and things!

If you don't clone this from your home directory, there are many things in the cluster-test/stackX/bin directory that must be edited. Be good to yourself and do it from ~.

```
    $ cd ~
    $ git clone 
```

github doesn't maintain file modes, so you'll want to do this to make life easier, later:


```
    $ chmod +x cluster-test/common/bin/*
    $ chmod +x cluster-test/ops/bin/*
    $ chmod +x cluster-test/stack1/bin/*
    $ chmod +x cluster-test/stack2/bin/*
    $ chmod +x cluster-test/stack3/bin/*
```

#### Domain Name Server

We only want a DNS server on the operations VM, so we don't want to do that, yet. 

Each VM will have its own ifcfg, so we don't want to do that, yet, either.

However, it's worth spending some time thinking about names. These instructions will create a `cluster.test` zone and the following names:
- ops
- stack1
    - zoo1
    - bookie1
    - broker1
    - pulsar1
    - cass1
- stack2
    - zoo2
    - bookie2
    - broker2
    - puslar2
    - cass2
- stack3
    - zoo3
    - bookie3
    - broker3
    - pulsar3
    - cass3
- dev

The five IPs will be 192.168.2.200, .201, .202, 203, and .210.

You do not need to do that. In fact, it is unlikely that your network, which we are **not** routing to but a part of, is using the 192.168.2.0/24 address space (aka class C network).

If you want to create a separate address space and routing, you're on your own. The DNS setup should work, though.

Note that it was originally going to be cluster.dev, but Google has broken the ".dev" top level domain for almost all browsers. It is hard-coded into the browsers - even Microsoft browsers - to use TLS (aka https://) connections to all .dev domains. This breaks many of the admin tools. ".test" is supposed to be reserved and seems to work fine.

#### Prometheus Node Exporter

In addition to generally monitoring your VMs, this provides a handy way to know they're all connected and working.

[Node Exporter](https://prometheus.io/docs/guides/node-exporter/) exposes Linux metrics to Prometheus. These instructions are copied directly from that link.

```
    $ wget https://github.com/prometheus/node_exporter/releases/download/v*/node_exporter-*.*-amd64.tar.gz
    $ tar xvfz node_exporter-*.*-amd64.tar.gz
```
https://github.com/prometheus/node_exporter/releases/download/v1.3.1/node_exporter-1.3.1.linux-amd64.tar.gz
You don't want to run it, yet, but it "just runs":

```
    $ cd node_exporter-*.*-amd64
    $ ./node_exporter
```

#### Firefox

This is not required for anything, although a browser is useful. If you want to use a different one, install it *before* the VM is copied.

Upgrade to the most recent version:

```
    $ sudo dnf update firefox
```

#### Docker

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

#### Eclipse and Java

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

#### Python

Do NOT install Python 2.x unless the world is coming to an end. Trying to manage both Python 2.x and Python 3.x is a nightmare.

We want to be sure that Python 3 is the default:

```
    $ sudo alternatives --config python
```

You shouldn't have a choice, but choosing the only option (Python 3) will make "python" run that one.

While you have Eclipse open, install the PyDev Python plugin from the Marketplace.

#### vi

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

#### bash

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
