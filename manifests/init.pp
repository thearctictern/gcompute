# manage instance in GCP

class gcompute(
  String $credential,
){
  file { $credential:
    ensure => file,
    source => 'puppet:///modules/profile/gcp.json',
  }->
  class { '::ruby':
    gems_version => 'latest',
  }->
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
  }
}
