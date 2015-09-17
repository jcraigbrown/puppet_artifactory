# Class: artifactory
#
# This module downloads Maven Artifacts from Artifactory
#
# Parameters:
# [*url*] : The Artifactory base url (mandatory)
# [*username*] : The username used to connect to artifactory
# [*password*] : The password used to connect to artifactory
#
# Actions:
# Checks and intialized the Artifactory support.
#
# Sample Usage:
#  class artifactory {
#   url      => 'http://artifactory.domain.com:8081',
#   username => 'user',
#   password => 'password',
# }
#
class artifactory(
  $url = '',
  $username = '',
  $password = '')
{

  # Check arguments
  # url mandatory
  if $url == '' {
    fail('Cannot initialize the Artifactory class - the url parameter is mandatory')
  }
  $artifactory_url = $url

  if ($username != '') and ($password == '') {
    fail('Cannot initialize the Artifactory class - both username and password must be set')
  } elsif ($username == '') and ($password != '') {
    fail('Cannot initialize the Artifactory class - both username and password must be set')
  } elsif ($username == '') and ($password == '') {
    $authentication = false
  } else {
    $authentication = true
    $user = $username
    $pwd = $password
  }

  # Install script
  file { '/opt/artifactory-script/download-artifact-from-artifactory.sh':
    ensure   => file,
    owner    => 'root',
    mode     => '0755',
    source   => 'puppet:///modules/artifactory/download-artifact-from-artifactory.sh',
    require  => File ['/opt/artifactory-script']
  }

  file { '/opt/artifactory-script':
    ensure => directory
  }	
}
