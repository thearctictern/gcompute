# manage instances in GCP

class gcompute(
  String $credential,
  Hash $gcp_machines,
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
  $gcp_machines.each |String $name, String $project, String $zone, String $machinetype, String $imagefamily, String $imageproject, String $sizeGB, String $network| {
    exec { 'Idempotent GCP Create':
      command => "gcloud compute instances create ${name} --project=${project} --zone=${zone} --machine-type=${machinetype} --create-disk=image-family=${imagefamily},image-project=${imageproject},size=${sizeGB} --image-family=${imagefamily} --image-project=${imageproject} --network=${network}",
      unless  => "\$(gcloud compute instances list | grep ${name} | awk -F' ' {'print \$1'}) == \"${name}\"",
    }
  }
}
