#!/bin/bash

# spoofing PT_ variables until we make this a task

export PT_credential=/home/puppet/da-discovery.json
export PT_name=da-instance-6
export PT_zone=us-east1-b
export PT_machinetype=n1-standard-1
export PT_imagefamily=centos-7
export PT_imageproject=centos-cloud
export PT_network=default
export PT_staticip=false # true|false
export PT_sizegb=50

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

      if [ $PT_name == $NAME ]; then
        echo 'This instance already exists. Please specify an instance name that is unique.'
        exit 1
      fi
done
export zonepass=false
for zoneInfo in $(gcloud compute zones list --format="csv[no-heading](name,region)")
do
  IFS=',' read -r -a zoneInfoArray<<< "$zoneInfo"
  ZONE="${zoneInfoArray[0]}"
  if [ $PT_zone == $ZONE ]; then
    echo "Zone $ZONE exists"
    export zonepass=true
  fi
done
if [ $zonepass = false ]; then
  echo "Zone $ZONE does not exist. Please specify a zone that exists."
  exit 1
fi
export typepass=false
for typeInfo in $(gcloud compute machine-types list --format="csv[no-heading](name,zone)")
do
  IFS=',' read -r -a typeInfoArray<<< "$typeInfo"
  TYPE="${typeInfoArray[0]}"
  TYPEZONE="${typeInfoArray[1]}"
  if [ $PT_machinetype == $TYPE ] && [ $PT_zone == $TYPEZONE ]; then
    echo "$TYPE exists in $TYPEZONE"
    export typepass=true
  fi
done
if [ $typepass = false ]; then
  echo "Either $TYPE doesn't exist, or it isn't available for the zone $TYPEZONE. Please try again."
  exit 1
fi
export imagepass=false
for imageInfo in $(gcloud compute images list --format="csv[no-heading](FAMILY,PROJECT)")
do
  IFS=',' read -r -a imageInfoArray<<< "$imageInfo"
  FAMILY="${imageInfoArray[0]}"
  PROJECT="${imageInfoArray[1]}"
  IMGFAMILY="$FAMILY:$PROJECT"
  if [ $PT_imagefamily == $FAMILY ] && [ $PT_imageproject == $PROJECT ]; then
    echo "$IMGFAMILY is a valid image family and project"
    export imagepass=true
  fi
done
if [ $imagepass = false ]; then
  echo "$IMGFAMILY doesn't exist. Please try again with a valid image family and project."
  exit 1
fi
export networkpass=false
for nwInfo in $(gcloud compute networks list --format="csv[no-heading](NAME)")
do
  IFS=',' read -r -a nwInfoArray<<< "$nwInfo"
  NETWORK="${nwInfoArray[0]}"
  if [ $PT_network == $NETWORK ]; then
    echo "$NETWORK network exists in this project"
    export networkpass=true
  fi
done
if [ $networkpass = false ]; then
  echo "$NETWORK doesn't exist. Please try again with a valid network."
  exit 1
fi
export sizeGB="${PT_sizegb}GB"
if [ $PT_staticip = false ]; then
  gcloud compute instances create $PT_name --zone=$PT_zone --machine-type=$PT_machinetype --create-disk=image-family=$PT_imagefamily,image-project=$PT_imageproject,size=$sizeGB --image-family=$PT_imagefamily --image-project=$PT_imageproject --network=$PT_network --no-address
else
  gcloud compute instances create $PT_name --zone=$PT_zone --machine-type=$PT_machinetype --create-disk=image-family=$PT_imagefamily,image-project=$PT_imageproject,size=$sizeGB --image-family=$PT_imagefamily --image-project=$PT_imageproject --network=$PT_network
fi
