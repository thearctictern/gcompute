
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

This module - still in development - provides tasks to use with Compute instances in Google Cloud Project.

## Setup

### Setup Requirements 

You'll need a bastion host to run this on. It can be any Red Hat, CentOS, Ubuntu or Debian host. Windows is coming soon. If the Google Cloud SDK isn't currently on it, the task will install it and you'll find it happily sitting at /usr/bin/gcloud.

You're going to need a Service Account with Owner privileges on your project. You can get the instructions for how to do this at https://cloud.google.com/iam/docs/creating-managing-service-accounts. It's easy to do, and you'll get a JSON file which you'll need to make available on the bastion host.

### Beginning with gcompute

Try out a simple sample task! Change the credential path to meet your need, and use an instance name that will be unique in your project.

`bolt task run gcompute::instance credential=/home/your_user/google.json name=da-instance-6 zone=us-east1-b machinetype=n1-standard-1 imagefamily=centos-7 imageproject=centos-cloud network=default staticip=false sizegb=50 project=some-gcp-project-i-have-perms-for --nodes some-node`

## Usage

Use the ::instance task with following parameters:

* **credential** - Path to your Service Account JSON file on the bastion host
* **name** - The unique name (within your project) for the instance you're creating
* **zone** - The zone you want to build the instance in
* **machinetype** - The machine type in GCP Compute you want to use. You can get a full list of these using the gcloud command, gcloud compute machine-types list
* **imagefamily** - The image family in GCP Compute you want to use. You can get a full list of these under the FAMILY column by running, gcloud compute images list
* **imageproject** - The project family in GCP Compute that the image you want to use belongs to. You can get a full list of these under the PROJECT column by running, gcloud compute images list. More info on this can be found at https://cloud.google.com/sdk/gcloud/reference/compute/images/list.
* **network** - The network you want to attach the instance to. It needs to exist already. If you're just starting out and not sure, use default.
* **staticip** - true/false. If true, this will create an external IP for you to connect to; if false, it won't. 
* **sizegb** - The size of the boot disk you'll associate with this image.
* **project** - A GCP project you have create permissions in.

Seems like a lot of tasks don't debug too well; this one creates a gcompute.XXXXXX in /tmp using mktemp and writes a tonne of stuff to it, and leaves it there for you to read so you know if something breaks, you can find out what (hopefully)!

## Limitations

Only works on Red Hat, CentOS, Ubuntu and Debian at the moment - I haven't put the logic in to install the SDK for Windows (yet).

I'm pretty new at this. You're probably going to run into something. Let me know - david@ternsoftware.org. That said, I'm fairly meticulous and hopefully this will work pretty well.

## Development

Probably submit a PR if you want to help out. Again, new at this.
