# manage instance in GCP

class gcompute(
  String $credential,
  String $instance_name,
  String $project,
  String $zone,
  String $machinetype,
  String $imagefamily,
  String $imageproject,
  String $sizeGB,
  String $network,
){
  package { [
    'googleauth',
    'google-api-client',
    ]:
    ensure   => present,
    provider => gem,
  }->
  gauth_credential { 'mycred':
    path     => $credential,
    provider => serviceaccount,
    scopes   => [
      'https://www.googleapis.com/auth/ndev.clouddns.readwrite',
    ],
  }->
  exec { 'Idempotent GCP Create':
    command => "gcloud compute instances create ${instance_name} --project=${project} --zone=${zone} --machine-type=${machinetype} --create-disk=image-family=${imagefamily},image-project=${imageproject},size=${sizeGB} --image-family=${imagefamily} --image-project=${imageproject} --network=${network}",
    unless  => "\$(gcloud compute instances list | grep ${instance_name} | awk -F' ' {'print \$1'}) == \"${instance_name}\"",
  }
}
