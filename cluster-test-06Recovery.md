# cluster-test: Recovering from Mistakes

## Table of Contents {#toc}

1. [BookKeeper Changes](#Recovering-bk)

## Recovering from Mistakes{#Recovering}

This can be difficult because the entire point of all this clustering is redundancy. 

If you need to start from scratch after running bookies, you will need to wipe the ZooKeeper data, which will
require starting Pulsar from scratch, too.

Cassandra also likes its redundancy and bringing the cluster up and down moves a lot of data. If you're doing
Cassandra work, I recommend leaving it running and putting the host to "sleep" rather than powering it down.

### BookKeeper Changes{#Recovering-bk}

BookKeeper has two cookies: One locally in the data directory and one in ZooKeeper. When those cookies do not match, it refuses to start. The error message will look like this:

```
01:56:34.017 [main] ERROR org.apache.bookkeeper.server.Main - Failed to build bookie server
org.apache.bookkeeper.bookie.BookieException$InvalidCookieException: Cookie
```

This is a dandy production feature to keep one from accidentally wiping out data by bringing up a misconfiged bookie. However, during development it can be annoying. Hopefully, I have made most of those mistakes for you. In case I have not:

Delete everything in the local data directory, where "stackX" below is 1, 2, or 3 (or all of them) depending on which bookie will not start.

```
    $ sudo rm -rf ~/cluster.dev/stackX/bookkeeper/data/*
```

If you remove the directory itself, watch permissions. Docker will recreate it as root owned. This may or may not matter to you. I find it annoying, but not fatal.

Delete the ZooKeeper cookie. You can either use [prettyZoo](cluster.dev-04Customization.md#VMs-prettyzoo) or wipe all of ZooKeeper, which has Pulsar implications, although I'm not sure what they are.

To remove them via prettyZoo, fire it up (on ops.cluster.dev):

```
    $ prettyZoo &
```

- Connect to any node in the cluster. If you haven't configured it, see the link above.
- Open the "ledgers" toggle.
- Open the revealed "cookies" toggle.
- Select the problem bookie (host:3181).
- Delete it, by right-clicking and choosing the "delete" option.
- Confirm the deletion.


