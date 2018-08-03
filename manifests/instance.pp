define gcompute::instance (
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
  exec { "Idempotent GCP Create ${instance_name}":
    command => "${gcloud_path} compute instances create ${instance_name} --project=${project} --zone=${zone} --machine-type=${machinetype} --create-disk=image-family=${imagefamily},image-project=${imageproject},size=${sizeGB} --image-family=${imagefamily} --image-project=${imageproject} --network=${network}",
    unless  => "/bin/test \"\$(${gcloud_path} compute instances list | grep -c \'da-instance-1[[:space:]]\')\" -eq 1",
  }
}
