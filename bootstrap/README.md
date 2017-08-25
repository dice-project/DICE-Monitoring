Deploying DMon
==================

This document describes two alternative ways of deploying DMON:

* [Using Vagrant](#vagrant-deployment)
* [Using Chef](#chef-deployment)
* [Using Cloudify](#cloudify-deployment)


Vagrant deployment
------------------

This is the easiest way of getting DMon up and running. Make sure you have
Vagrant and VirtualBox installed and then execute
`vagrant up --provider virtualbox`. This command will create new virtual
machine and install DMon onto it.

When the process is done, visit `localhost:5001` to get to the DMon's rest
service. Another end point that is exposed is `localhost:5601` that points to
Kibana's user interface.


Chef deployment
---------------

In a dedicated Ubuntu 14.04 host, first install the
[Chef client](https://downloads.chef.io/chef#ubuntu), e.g.:

```bash
$ wget https://packages.chef.io/files/stable/chef/12.18.31/ubuntu/14.04/chef_12.18.31-1_amd64.deb
$ sudo dpkg -i chef_12.18.31-1_amd64.deb
```

Then obtain this cookbook repository:

```bash
$ git clone https://github.com/dice-project/DICE-Chef-Repository.git
$ cd DICE-Chef-Repository
4 git checkout develop
```

Before we run the installation, we need to provide the configuration of the
DMon to be bootstrapped. We name the configuration file as `dmon.json` and
populate it with the following contents:

```json
{
  "java": {
    "jdk_version": "8",
    "install_flavor": "openjdk"
  },
  "cloudify": {
    "node_id": "dmon-node",
    "deployment_id": "dmon-deploy-id"
  },
  "dmon": {
    "openssl_conf": "[req]\ndistinguished_name = req_distinguished_name\nx509_extensions = v3_req\nprompt = no\n[req_distinguished_name]\nC = SL\nST = Slovenia\nL =  Ljubljana\nO = Xlab\nCN = *\n[v3_req]\nsubjectKeyIdentifier = hash\nauthorityKeyIdentifier = keyid,issuer\nbasicConstraints = CA:TRUE\nsubjectAltName = IP:0.0.0.0\n[v3_ca]\nkeyUsage = digitalSignature, keyEncipherment\nsubjectAltName = IP:0.0.0.0\n"
  }
}
```

Then use Chef client in its zero mode to execute the recipes:

```bash
$ sudo chef-client -z \
  -j dmon.json \
  -o recipe[dice_common::host],recipe[apt::default],recipe[java::default],recipe[dmon::default],recipe[dmon::elasticsearch],recipe[dmon::kibana],recipe[dmon::logstash]
```


Cloudify deployment
-------------------

This process will create a new node in the target platform (FCO or OpenStack)
and install the whole DMon stack on top of it.

### Preparing environment

This approach requires a running Cloudify Manager in the infrastructure
environment. If you do not have it installed yet, you will find complete
instructions for installing Cloudify Manager, DICE Deployment Service and
DICE Monitoring Platform in [these instructions][DDS-AdminGuide].

For an existing Cloudify Manager instance, please note down:

* IP address of the service - `CFY_ADDRESS`
* Port for the service (usually 443) - `CFY_PORT`
* Administrator's username - `CFY_USERNAME`
* Administrator's password - `CFY_PASSWORD`

Obtain the DICE Deployment Service code (it contains useful tools and
configuration file templates):

    $ mkdir ~/dds && cd ~/dds
    $ git clone --depth 1 --branch master \
        https://github.com/dice-project/DICE-Deployment-Service.git

Next, obtain the DICE Monitoring Platform's code:

    $ mkdir -p ~/dmon && cd ~/dmon
    $ git clone --depth 1 --branch master \
        https://github.com/dice-project/DICE-Monitoring.git
    $ cd DICE-Monitoring/bootstrap

Set up the Python virtual environment. For RedHat related GNU/Linux
distributions, following packages need to be installed: `python-virtualenv` and
`python-devel`. Adjust properly for Ubuntu and the like. Then run:

    $ virtualenv venv
    $ . venv/bin/activate
    $ pip install cloudify==3.4.2
    $ pip install -U requests[security]

We now have the Cloudify command line tools installed. Next, we will configure
them. This involves obtaining the service's TLS certificate. Along the way, we
will set up the environment variables. Please replace the `CFY_*` strings with
proper values:

    $ export CFY_ADDRESS=CFY_ADDRESS
    $ export CFY_PORT=CFY_PORT
    $ openssl s_client -connect $CFY_ADDRESS:$CFY_PORT < /dev/null 2> /dev/null \
        | openssl x509 -out cfy.crt

We create a configuration file for Cloudify and source it. Again, replace
the `CFY_*` with the actual values:

    $ echo "export CLOUDIFY_USERNAME=CFY_USERNAME" > cloudify.inc.sh
    $ echo "export CLOUDIFY_PASSWORD=CFY_PASSWORD" >> cloudify.inc.sh
    $ echo "export CLOUDIFY_SSL_CERT=$PWD/cfy.crt" >> cloudify.inc.sh

Source the configuration and configure the `cfy` tool:

    $ . ./cloudify.inc.sh
    $ cfy init
    $ cfy use -t $CFY_ADDRESS --port $CFY_PORT

The tool should now work with your Cloudify Manager:

    $ cfy status
    Getting management services status... [ip=109.231.122.46]
    Services:
    +--------------------------------+---------+
    |            service             |  status |
    +--------------------------------+---------+
    | InfluxDB                       | running |
    | Celery Management              | running |
    | Logstash                       | running |
    | RabbitMQ                       | running |
    | AMQP InfluxDB                  | running |
    | Manager Rest-Service           | running |
    | Cloudify UI                    | running |
    | Webserver                      | running |
    | Riemann                        | running |
    | Elasticsearch                  | running |
    +--------------------------------+---------+

### Preparing inputs

From the DICE Deployment Service code's `install/` folder, select a suitable
`PLATFORM-dds-config.inc.sh`, where `PLATFORM` is either `aws`, `fco` or
`openstack`, and copy it into your working folder. For example, if your cloud
platform is AWS, use:

    $ cp ~/dds/DICE-Deployment-Service/install/openstack-dds-config.inc.sh \
        dds-config.inc.sh

Open the `dds-config.inc.sh` for editing and supply the actual values to the
variables. Use the comments in the template and instructions from
[this guide][DDS-AdminGuide] to help you:

    $ $EDITOR dds-config.inc.sh

We need to edit one more configuration file, `config.inc.sh`, which contains
settings specific to the DICE Monitoring Platform:

    $ $EDITOR config.inc.sh

Then, source both configuration files:

    $ . dds-config.inc.sh
    $ . config.inc.sh

### Running the installation

To start the installation, choose a name for the deployment (or leave the
default name `dmon`) and run the installation script:

    $ ./install-dmon.sh dmon
    Creating deployment inputs for DICE Monitoring Service
    Running installation
    Publishing blueprint
    Uploading blueprint blueprint.yaml...
    Blueprint uploaded. The blueprint's id is dmon
    Creating deploy
    Processing inputs source: inputs.yaml
    Creating new deployment from blueprint dmon...
    Deployment created. The deployment's id is dmon
    Starting execution
    Executing workflow install on deployment dmon [timeout=900 seconds]
    Deployment environment creation is in progress...
    [...]
    Finished executing workflow install on deployment dmon
    Outputs:
    Retrieving outputs for deployment dmon...
     - "kibana_url":
         Description: Address of the Kibana web interface
         Value: http://10.10.43.194:5601
     - "dmon_address":
         Description: Internal address of the DICE Monitoring services host
         Value: 10.50.51.8

    Obtaining outputs
    Creating DICE Deployment Service's runtime inputs - the DMon values

    -----------------------------------------------------------------------------
    SUMMARY:
      Kibana URL: http://10.10.43.194:5601
      Private DMon address: 10.50.51.8
    -----------------------------------------------------------------------------

This step will take a while. When it is done, the summary section will show
the data about the deployed DICE Monitoring Service. In particular, Kibana URL
can be readily used with a browser.

The script also produces a file `dmon_inputs.json`, which can be useful for
configuring the DICE Deployment Service.

### Configuring the DICE Deployment Service

The best way to use DICE Monitoring is to let the DICE Deployment Service
automatically register the applications being deployed. To do this, the
DICE Deployment Service needs to be configured with the DICE Monitoring
service's details. The previous step has produced the file `dmon_inputs.json`
that we will use for this purpose. This file contains only the monitoring
related inputs, therefore we have to merge it with the other inputs:

    $ ~/dds/DICE-Deployment-Service
    $ tools/merge-inputs.sh ~/dmon/DICE-Monitoring/bootstrap/dmon_inputs.json \
        merged_inputs.json

The result of this step is `merged_inputs.json`, which we can now send to
the DICE Deployment Service:

    $ dice-deploy-cli set-inputs merged_inputs.json


### Removing deployment

The DMon deployment can be uninstalled using the following call:

    $ ./dw.sh dmon

[DDS-AdminGuide]: https://github.com/dice-project/DICE-Deployment-Service/blob/master/doc/AdminGuide.md
