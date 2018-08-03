# manage instance in GCP

class gcompute {
  class { '::ruby':
    gems_version => 'latest',
  }
  package { [
    'googleauth',
    'google-api-client',
    ]:
    ensure   => present,
    provider => gem,
  }
  include gcloudsdk
}
