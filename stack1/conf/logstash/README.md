# cluster-test logstash configuration

## config

This is [logstash.yml](https://www.elastic.co/guide/en/logstash/current/logstash-settings-file.html) is well documented. The only option set:
- xpack.monitoring.elasticsearch.hosts: [ "http://elastic.cluster.test:9200" ]

One assumes `jvm.options` are standard.

The `startup.properties` seem fairly obvious. The only option set:
- LS_SETTINGS_DIR=/usr/share/logstash/config

`pipelines.yml` is not at all obvious and lightly documented. I eventually figured out that pipeline configuration (documented as .cfg) and [file configuration](https://www.elastic.co/guide/en/logstash/current/config-examples.html) (documented as .conf) are the same thing.

There is a pipeline for each component. I'm not sure why they are in a dedicated directory, but I followed the pattern:

```
    - pipeline.id: zoo1
      path.config: "pipeline/zoo1.conf"
    - pipeline.id: bookie1
      path.config: "pipeline/bookie1.conf"
    - pipeline.id: broker1
      path.config: "pipeline/broker1.conf"
    - pipeline.id: cass1
      path.config: "pipeline/cass1.conf"
```

I went with the .conf naming convention for no particular reason.

## pipeline

The input parts are easy, given the log file pattern.

```
input {
  file {
    path => "zookeeperlogs/zookeeper1.log"
    start_position => "beginning"
  }
}
```
where "zookeeper1" is "zookeeperX" and "zookeeper" is "zookeeper", "bookkeeper", "broker", and "cassandra".

The output parts are easy.

```
output {
  elasticsearch {
    hosts => ["elastic.cluter.test:9200"]
  }
}
```

adding

```
    stdout { codec => rubydebug }
```

generates docker logs data that's handy for debugging the filters, which are not at all easy. 

This is currently configured. Unless you are doing something with logstash, it's a giant waste, so you may want to turn it off.

Two good tutorials: [https://logz.io/blog/logstash-grok/](https://logz.io/blog/logstash-grok/) and [https://www.tutorialspoint.com/logstash/logstash_transforming_the_logs.htm](https://www.tutorialspoint.com/logstash/logstash_transforming_the_logs.htm)

### ZooKeeper

This is the GROK expression for ZooKeeper logs: 


```
    match => { "message" => "%{TIME:time} \[%{DATA:thread}\] %{LOGLEVEL:loglevel} %{DATA:class} - %{GREEDYDATA:logdata}"  }
```

Nothing interesting is logged, so I'm just sending Leader/Follower update  messages, which are nodes joining the cluster.

