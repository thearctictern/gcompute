define gcompute::instance (
  String $credential,
  String $gcloud_path,
  String $project,
  String $zone,
  String $machinetype,
  String $imagefamily,
  String $imageproject,
  String $sizeGB,
  String $network,
  String $instance_name = $title,
){
  exec { "Idempotent GCP Login for ${instance_name} create":
    command => "${gcloud_path} auth activate-service-account --key-file=${credential}",
    onlyif  => "/bin/test -z `${gcloud_path} auth list --filter=status:ACTIVE --format=\"value(account)\"`",
  }
  exec { "Idempotent GCP Create ${instance_name}":
    command => "${gcloud_path} compute instances create ${instance_name} --project=${project} --zone=${zone} --machine-type=${machinetype} --create-disk=image-family=${imagefamily},image-project=${imageproject},size=${sizeGB} --image-family=${imagefamily} --image-project=${imageproject} --network=${network}",
    unless  => "/bin/test \"\$(${gcloud_path} compute instances list | grep -c \'${instance_name}[[:space:]]\')\" -eq 1",
  }
}
