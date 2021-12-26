# cluster-test Ops

##  Ops Specifics

Specifics for the ops VM:

### bin

The usual up/dow/tail commands

### conf

#### Kibana

It looks as if Elasticsearch is the group to emulate with Docker packaging and the annoying "environment variables don't match configuration files" thing:

> For compatibility with container orchestration systems, these environment variables are written in all capitals, with underscores as word separators. The helper translates these names to valid Kibana setting names.


