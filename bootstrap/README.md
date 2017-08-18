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

We will assume that we have arrived here from having [just installed the
DICE Deployment Service and Cloudify Manager](https://github.com/dice-project/DICE-Deployment-Service/blob/master/doc/AdminGuide.md). Previously we have created a `~/dds` folder, which contains a Python virtual environment `venv/`
and a DICE Deployment Service code folder `DICE-Deployment-Service`. If that is
the case, we make sure that the virtual environment is activated and that the
existing environment variables are sourced:

    $ . ~/dds/venv/bin/activate
    $ . ~/dds/DICE-Deployment-Service/dds-config.inc.sh

If this works, proceed to [preparing working environment](#preparing-working-environment)

If this is not the case, then ... **TODO**

For Redhat related GNU/Linux distributions, following packages need to be
installed: `python-virtualenv` and `python-devel`. Adjust properly for
Ubuntu and the like.

Now create new folder, create new python virtual environment and install
`cloudify` package.

    $ mkdir -p ~/dds && cd ~/dds
    $ virtualenv venv
    $ . venv/bin/activate
    $ pip install cloudify==3.4.2
    $ pip install -U requests[security]

Build the configuration environment for your Cloudify Manager instance, making
sure to replace `CFY_USERNAME` and `CFY_PASSWORD` with the actual values:

    $ mkdir ~/cfy-manager && cd ~/cfy-manager
    $ cp $CLOUDIFY_SSL_CERT cfy.crt
    $ echo "export CLOUDIFY_USERNAME=CFY_USERNAME" > cloudify.inc.sh
    $ echo "export CLOUDIFY_PASSWORD=CFY_PASSWORD" >> cloudify.inc.sh
    $ echo "export CLOUDIFY_SSL_CERT=$PWD/cfy.crt" >> cloudify.inc.sh

### Preparing working environment

TODO

    $ mkdir -p ~/dmon && cd ~/dmon
    $ git clone --depth 1 --branch master \
        https://github.com/dice-project/DICE-Monitoring.git
    $ cd DICE-Monitoring/bootstrap

    $ . ~/cfy-manager/cloudify.inc.sh
    $ cfy init
    $ cfy use -t CFY_ADDRESS --port CFY_PORT

Make sure you replace `CFY_*` placeholders with Cloudify Manager data. To test
if everything works, execute `cfy status`. This command should output
something similar to this:

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

Installation of DICE Monitoring Service depends on environment parameters we set
earlier in `~/dds/DICE-Deployment-Service/dds-config.inc.sh` and the ones that
we need to provide in `config.inc.sh`. Use your editor to provide the
parameters:

    $ $EDITOR config.inc.sh

Then, source this configuration file:

    $ . config.inc.sh

### Running the installation

To start the installation, choose a name for the deployment (or leave the
default name `dmon`) and run the installation script: **TODO** actual output

    $ ./install-dmon.sh dmon

### Removing deployment

The DMon deployment can be uninstalled using the following call:

    $ ./dw.sh dmon
