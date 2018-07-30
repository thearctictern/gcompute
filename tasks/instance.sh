#!/bin/bash

debug="$(mktemp /tmp/gcompute.XXXXXXXX)"
export DISTRO=`head /etc/os-release -n 1 | awk -F'=' '{print $2}' | sed 's/"//g'`

# check that gcloud sdk has been installed
if [[ ( $DISTRO == "Red Hat Enterprise Linux Server" ) || ( $DISTRO == "CentOS Linux" ) ]]; then
  if [[ -n $(find / -wholename '*/bin/gcloud' 2> /dev/null) ]]; then 
    export GCLOUD_PATH=$(find / -wholename '*/bin/gcloud' 2> /dev/null | head -n 1)
  else
    tee -a /etc/yum.repos.d/google-cloud-sdk.repo << EOM
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
elif [[ ( $DISTRO == "Ubuntu" ) || ( $DISTRO =~ "^Debian.*$" ) ]]; then
  if [[ -n $(find / -wholename '*/bin/gcloud' 2> /dev/null) ]];then 
      export GCLOUD_PATH=$(find / -wholename '*/bin/gcloud' 2> /dev/null | head -n 1)
  else
    export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"
    echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
    apt-get update && apt-get install -y google-cloud-sdk
    export GCLOUD_PATH=/usr/bin/gcloud
  fi
else
  echo "This distribution $DISTRO is not currently supported." >> $debug
  exit 1
fi

echo "Path to gcloud binary is $GCLOUD_PATH" >> $debug

# let's make sure we have a json service account file

if [ ! -f $PT_credential ]; then
  echo 'Credentials file does not exist - please specify a path to a correct credentials file in json format.' >> $debug
  exit 1
else 
  echo "Found a credential file $PT_credential" >> $debug
fi

$GCLOUD_PATH auth activate-service-account --key-file=${PT_credential}
$GCLOUD_PATH config set project $PT_project

for scopesInfo in $(gcloud compute instances list --format="csv[no-heading](name,id,serviceAccounts[].email.list(),serviceAccounts[].scopes[].map().list(separator=;))")
do
      IFS=',' read -r -a scopesInfoArray<<< "$scopesInfo"
      NAME="${scopesInfoArray[0]}"
      ID="${scopesInfoArray[1]}"
      EMAIL="${scopesInfoArray[2]}"
      SCOPES_LIST="${scopesInfoArray[3]}"

      if [ $PT_name == $NAME ]; then
        echo 'This instance already exists. Please specify an instance name that is unique.' >> $debug
        exit 1
      fi
done
export zonepass=false
for zoneInfo in $(gcloud compute zones list --format="csv[no-heading](name,region)")
do
  IFS=',' read -r -a zoneInfoArray<<< "$zoneInfo"
  ZONE="${zoneInfoArray[0]}"
  if [ $PT_zone == $ZONE ]; then
    echo "Zone $ZONE exists" >> $debug
    export zonepass=true
  fi
done
if [ $zonepass = false ]; then
  echo "Zone $ZONE does not exist. Please specify a zone that exists." >> $debug
  exit 1
fi
export typepass=false
for typeInfo in $(gcloud compute machine-types list --format="csv[no-heading](name,zone)")
do
  IFS=',' read -r -a typeInfoArray<<< "$typeInfo"
  TYPE="${typeInfoArray[0]}"
  TYPEZONE="${typeInfoArray[1]}"
  if [ $PT_machinetype == $TYPE ] && [ $PT_zone == $TYPEZONE ]; then
    echo "$TYPE exists in $TYPEZONE" >> $debug
    export typepass=true
  fi
done
if [ $typepass = false ]; then
  echo "Either $TYPE doesn't exist, or it isn't available for the zone $TYPEZONE. Please try again." >> $debug
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
    echo "$IMGFAMILY is a valid image family and project" >> $debug
    export imagepass=true
  fi
done
if [ $imagepass = false ]; then
  echo "$IMGFAMILY doesn't exist. Please try again with a valid image family and project." >> $debug
  exit 1
fi
export networkpass=false
for nwInfo in $(gcloud compute networks list --format="csv[no-heading](NAME)")
do
  IFS=',' read -r -a nwInfoArray<<< "$nwInfo"
  NETWORK="${nwInfoArray[0]}"
  if [ $PT_network == $NETWORK ]; then
    echo "$NETWORK network exists in this project" >> $debug
    export networkpass=true
  fi
done
if [ $networkpass = false ]; then
  echo "$NETWORK doesn't exist. Please try again with a valid network." >> $debug
  exit 1
fi
export sizeGB="${PT_sizegb}GB"
if [ $PT_staticip == "false" ]; then
  gcloud compute instances create $PT_name --zone=$PT_zone --machine-type=$PT_machinetype --create-disk=image-family=$PT_imagefamily,image-project=$PT_imageproject,size=$sizeGB --image-family=$PT_imagefamily --image-project=$PT_imageproject --network=$PT_network --no-address >>$debug 2>&1
else
  gcloud compute instances create $PT_name --zone=$PT_zone --machine-type=$PT_machinetype --create-disk=image-family=$PT_imagefamily,image-project=$PT_imageproject,size=$sizeGB --image-family=$PT_imagefamily --image-project=$PT_imageproject --network=$PT_network >>$debug 2&>1
fi
