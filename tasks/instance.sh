#!/bin/bash

# spoofing PT_ variables until we make this a task

export PT_credential=/home/puppet/da-discovery.json

# check that gcloud sdk has been installed

if [[ -n $(find / -wholename '*/bin/gcloud' 2> /dev/null) ]];then 
  export GCLOUD_PATH=$(find / -wholename '*/bin/gcloud' 2> /dev/null | head -n 1)
else
  sudo tee -a /etc/yum.repos.d/google-cloud-sdk.repo << EOM
    [google-cloud-sdk]
    name=Google Cloud SDK
    baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-x86_64
    enabled=1
    gpgcheck=1
    repo_gpgcheck=1
    gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOM
  yum install google-cloud-sdk -y
  export GCLOUD_PATH=/usr/bin/gcloud
fi

echo $GCLOUD_PATH

# let's make sure we have a json service account file

if [ ! -f $PT_credential ]; then
  echo 'Credentials file does not exist - please specify a path to a correct credentials file in json format.'
  exit 1
fi
