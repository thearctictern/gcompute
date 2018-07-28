#!/bin/bash

# spoofing PT_ variables until we make this a task

export PT_credential=/home/puppet/da-discovery.json
export PT_name=da-instance-5
export PT_action=create

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

gcloud auth activate-service-account --key-file $PT_credential

for scopesInfo in $(gcloud compute instances list --format="csv[no-heading](name,id,serviceAccounts[].email.list(),serviceAccounts[].scopes[].map().list(separator=;))")
do
      IFS=',' read -r -a scopesInfoArray<<< "$scopesInfo"
      NAME="${scopesInfoArray[0]}"
      ID="${scopesInfoArray[1]}"
      EMAIL="${scopesInfoArray[2]}"
      SCOPES_LIST="${scopesInfoArray[3]}"

      echo "NAME: $NAME, ID: $ID, EMAIL: $EMAIL"
      for instance in $NAME
      do
        if [ $PT_name == $instance ] && [ $PT_action == 'create' ]; then
          echo 'This instance already exists. Please specify an instance name that is unique.'
          exit 1
        fi
      done 
done
