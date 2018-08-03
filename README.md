
# gcompute

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with compute](#setup)
    * [What compute affects](#what-compute-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with compute](#beginning-with-compute)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Limitations - OS compatibility, etc.](#limitations)
5. [Development - Guide for contributing to the module](#development)

## Description

This module provides classes and tasks to use with Compute instances in Google Cloud Project.

## Setup

### Setup Requirements 

You'll need a bastion host to run this on. It can be any Red Hat, CentOS, Ubuntu or Debian host. Windows is coming soon. 

You should include the 'gcompute' class in the role somewhere for this host. A sample configuration is below. This will install a couple of useful gems and the Google Cloud SDK for you.

When you run the `gcompute::instance` task using this node as a target, if the Google Cloud SDK isn't currently on it, the task will install it and you'll find it happily sitting at /usr/bin/gcloud.

You're going to need a Service Account with Owner privileges on your project. You can get the instructions for how to do this at https://cloud.google.com/iam/docs/creating-managing-service-accounts. It's easy to do, and you'll get a JSON file which you'll need to make available on the bastion host. 

### Beginning with gcompute

Try out a simple sample task! Change the credential path to meet your need, and use an instance name that will be unique in your project.

`puppet task run gcompute::instance credential=/home/your_user/google.json name=da-instance-6 zone=us-east1-b machinetype=n1-standard-1 imagefamily=centos-7 imageproject=centos-cloud network=default staticip=false sizegb=50 project=some-gcp-project-i-have-perms-for --nodes some-node`

## Usage

The best approach is to be using Roles and Profiles. Include the gcompute class in your profile to setup some prerequisites, and then use the gcompute::instance in a splatted hash to build and maintain your machines:

```
class profile::gcompute(
  String $credential,
  Hash $gcp_machines,
  String $gcloudpath,
){
  include gcompute
  $gcp_machines.each |String $instance_name, Hash $attributes| {
    gcompute::instance { $instance_name:
      credential    => $credential,
      gcloud_path   => $gcloudpath,
      instance_name => $instance_name,
      *             => $attributes,
    }
  }
}
```

The accompanying Hiera should look something like this:

```
---

profile::gcompute::credential: /home/puppet/gcp.json
profile::gcompute::gcloudpath: /usr/bin/gcloud
profile::gcompute::gcp_machines:
  instance-1:
    project: some-gcp-project
    zone: us-east1-b
    machinetype: g1-small
    imagefamily: centos-7 
    imageproject: centos-cloud 
    sizeGB: 50GB 
    network: default
  instance-2:
    project: some-gcp-project
    zone: us-east1-b
    machinetype: f1-micro
    imagefamily: centos-7 
    imageproject: centos-cloud 
    sizeGB: 50GB 
    network: default
```

The defined type `gcompute::instance` looks like this, if you want to use it differently:

```
define gcompute::instance (
  String $credential,
  String $gcloud_path,
  String $instance_name = $title,
  String $project,
  String $zone,
  String $machinetype,
  String $imagefamily,
  String $imageproject,
  String $sizeGB,
  String $network,
){
  exec { "Idempotent GCP Login for ${instance_name} create":
    command => "${gcloud_path} auth activate-service-account --key-file=${credential}",
    onlyif  => "/bin/test -z \`${gcloud_path} auth list --filter=status:ACTIVE --format=\"value(account)\"\`",
  }
  exec { "Idempotent GCP Create ${instance_name}":
    command => "${gcloud_path} compute instances create ${instance_name} --project=${project} --zone=${zone} --machine-type=${machinetype} --create-disk=image-family=${imagefamily},image-project=${imageproject},size=${sizeGB} --image-family=${imagefamily} --image-project=${imageproject} --network=${network}",
    unless  => "/bin/test \"\$(${gcloud_path} compute instances list | grep -c \'${instance_name}[[:space:]]\')\" -eq 1",
  }
}
```

One day I'll replace the execs with actual types hitting the API, but not today. This works really well for the moment though.

## Tasks

Use the ::instance task with following parameters:

* **credential** - Path to your Service Account JSON file on the bastion host
* **name** - The unique name (within your project) for the instance you're creating
* **zone** - The zone you want to build the instance in
* **machinetype** - The machine type in GCP Compute you want to use. You can get a full list of these using the gcloud command, gcloud compute machine-types list
* **imagefamily** - The image family in GCP Compute you want to use. You can get a full list of these under the FAMILY column by running, gcloud compute images list
* **imageproject** - The project family in GCP Compute that the image you want to use belongs to. You can get a full list of these under the PROJECT column by running, gcloud compute images list. More info on this can be found at https://cloud.google.com/sdk/gcloud/reference/compute/images/list.
* **network** - The network you want to attach the instance to. It needs to exist already. If you're just starting out and not sure, use default.
* **staticip** - true/false. If true, this will create an external IP for you to connect to; if false, it won't. 
* **sizegb** - The size of the boot disk you'll associate with this image, appended with GB - e.g. "50GB"
* **project** - A GCP project you have create permissions in.

Seems like a lot of tasks don't debug too well; this one creates a gcompute.XXXXXX in /tmp using mktemp and writes a tonne of stuff to it, and leaves it there for you to read so you know if something breaks, you can find out what (hopefully)!

## Limitations

Only works on Red Hat, CentOS, Ubuntu and Debian at the moment - I haven't put the logic in for Windows (yet).

I'm pretty new at this. You're probably going to run into something. Let me know - david@ternsoftware.org. That said, I'm fairly meticulous and hopefully this will work pretty well.

## Development

Probably submit a PR if you want to help out. Again, new at this.
