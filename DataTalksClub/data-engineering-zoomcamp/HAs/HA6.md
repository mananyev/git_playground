# DTC data-engineering-zoomcamp HA6

## 0. Preparations

Ran `docker-compose up -d` in the folder with [docker-compose.yml](../code/week6/docker-compose.yml) file to set kafka and redpandas as in the [pyflink module](https://github.com/DataTalksClub/data-engineering-zoomcamp/tree/main/06-streaming/pyflink).


## 1. Questions
### 1.1 Redpanda version
After all the services are up, I ran:

```bash
docker-compose exec redpanda-1 rpk help
```

I got the help output (see below)

<details>
<summary><b>see help output</b></summary>

```bash
rpk is the Redpanda CLI & toolbox

Usage:
  rpk [flags]
  rpk [command]

Available Commands:
  cloud       Interact with Redpanda cloud
  cluster     Interact with a Redpanda cluster
  connect     A stream processor for mundane tasks - https://docs.redpanda.com/redpanda-connect
  container   Manage a local container cluster
  debug       Debug the local Redpanda process
  generate    Generate a configuration template for related services
  group       Describe, list, and delete consumer groups and manage their offsets
  help        Help about any command
  iotune      Measure filesystem performance and create IO configuration file
  plugin      List, download, update, and remove rpk plugins
  profile     Manage rpk profiles
  redpanda    Interact with a local Redpanda process
  registry    Commands to interact with the schema registry
  security    Manage Redpanda security
  topic       Create, delete, produce to and consume from Redpanda topics
  transform   Develop, deploy and manage Redpanda data transforms
  version     Prints the current rpk and Redpanda version

Flags:
      --config string            Redpanda or rpk config file;
                                 default search paths are
                                 "/var/lib/redpanda/.config/rpk/rpk.yaml", $PWD/redpanda.yaml, and /etc/redpanda/redpanda.yaml
  -X, --config-opt stringArray   Override rpk configuration
                                 settings; '-X help' for
                                 detail or '-X list' for
                                 terser detail
  -h, --help                     Help for rpk
      --profile string           rpk profile to use
  -v, --verbose                  Enable verbose logging
      --version                  version for rpk

Use "rpk [command] --help" for more information about a command.
```
</details><br />

According to this help output, the command I need to run is `docker-compose exec redpanda-1 rpk --version` gives

```bash
rpk version v24.2.18 (rev f9a22d4430)
```


## 1.2 Creating a topic

With
```bash
docker-compose exec redpanda-1 rpk topic create green-taxi
```

command, I get 

```
TOPIC       STATUS
green-taxi  OK
```


## 1.3 Connecting to the Kafka server

Ran the [`connector.py`](../code/week6/connector.py) file and got

```bash
True
```

(:


## 1.4 Sending the Trip Data

Ran the [sending_data.py](../code/week6/sending_data.py) file and got the output

```
took 105.29 seconds
```


## 1.5 Build a Sessionization Window
