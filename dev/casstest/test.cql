CREATE KEYSPACE IF NOT EXISTS cluster
    WITH replication={'class': 'NetworkTopologyStrategy', 'cluster.test' : 3}
    AND durable_writes = true;
USE cluster;
CREATE TABLE IF NOT EXISTS named_zone (
    zone text,
    name text,
    ipv4 text,
    PRIMARY KEY ((zone), name)
) WITH comment='named zone data for cluster.test';
INSERT INTO named_zone 
    ( zone, name, ipv4 )
    VALUES
    ( 'cluster.test', 'ops', '192.168.2.200' );
INSERT INTO named_zone 
    ( zone, name, ipv4 )
    VALUES
    ( 'cluster.test', 'elastic', '192.168.2.200' );
INSERT INTO named_zone 
    ( zone, name, ipv4 )
    VALUES
    ( 'cluster.test', 'kibana', '192.168.2.200' );
INSERT INTO named_zone 
    ( zone, name, ipv4 )
    VALUES
    ( 'cluster.test', 'prometheus', '192.168.2.200' );
INSERT INTO named_zone 
    ( zone, name, ipv4 )
    VALUES
    ( 'cluster.test', 'grafana', '192.168.2.200' );
INSERT INTO named_zone 
    ( zone, name, ipv4 )
    VALUES
    ( 'cluster.test', 'stack1', '192.168.2.201' );
INSERT INTO named_zone 
    ( zone, name, ipv4 )
    VALUES
    ( 'cluster.test', 'zoo1', '192.168.2.201' );
INSERT INTO named_zone 
    ( zone, name, ipv4 )
    VALUES
    ( 'cluster.test', 'bookie1', '192.168.2.201' );
INSERT INTO named_zone 
    ( zone, name, ipv4 )
    VALUES
    ( 'cluster.test', 'broker1', '192.168.2.201' );
INSERT INTO named_zone 
    ( zone, name, ipv4 )
    VALUES
    ( 'cluster.test', 'proxy1', '192.168.2.201' );
INSERT INTO named_zone 
    ( zone, name, ipv4 )
    VALUES
    ( 'cluster.test', 'cass1', '192.168.2.201' );
INSERT INTO named_zone 
    ( zone, name, ipv4 )
    VALUES
    ( 'cluster.test', 'stack2', '192.168.2.202' );
INSERT INTO named_zone 
    ( zone, name, ipv4 )
    VALUES
    ( 'cluster.test', 'zoo2', '192.168.2.202' );
INSERT INTO named_zone 
    ( zone, name, ipv4 )
    VALUES
    ( 'cluster.test', 'bookie2', '192.168.2.202' );
INSERT INTO named_zone 
    ( zone, name, ipv4 )
    VALUES
    ( 'cluster.test', 'broker2', '192.168.2.202' );
INSERT INTO named_zone 
    ( zone, name, ipv4 )
    VALUES
    ( 'cluster.test', 'proxy2','192.168.2.201' );
INSERT INTO named_zone 
    ( zone, name, ipv4 )
    VALUES
    ( 'cluster.test', 'cass2', '192.168.2.202' );
INSERT INTO named_zone 
    ( zone, name, ipv4 )
    VALUES
    ( 'cluster.test', 'stack3', '192.168.2.203' );
INSERT INTO named_zone 
    ( zone, name, ipv4 )
    VALUES
    ( 'cluster.test', 'zoo3', '192.168.2.203' );
INSERT INTO named_zone 
    ( zone, name, ipv4 )
    VALUES
    ( 'cluster.test', 'bookie3', '192.168.2.203' );
INSERT INTO named_zone 
    ( zone, name, ipv4 )
    VALUES
    ( 'cluster.test', 'broker3', '192.168.2.203' );
INSERT INTO named_zone 
    ( zone, name, ipv4 )
    VALUES
    ( 'cluster.test', 'proxy3', '192.168.2.201' );
INSERT INTO named_zone 
    ( zone, name, ipv4 )
    VALUES
    ( 'cluster.test', 'cass3', '192.168.2.203' );
INSERT INTO named_zone 
    ( zone, name, ipv4 )
    VALUES
    ( 'cluster.test', 'dev', '192.168.2.210' );


