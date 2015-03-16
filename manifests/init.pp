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
  $ARTIFACTORY_URL = $url

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

  if $::operatingsystem == 'windows' {
    $installdir = 'C:\ProgramData\artifactory-script'
    $scriptname = 'download-artifact-from-artifactory.ps1'
    File { source_permissions => ignore }
  } else {
    $installdir = '/opt/artifactory-script'
    $scriptname = 'download-artifact-from-artifactory.sh'
  }

  # Install script
  file { "${installdir}/${scriptname}":
    ensure  => file,
    mode    => '0755',
    source  => "puppet:///modules/artifactory/${scriptname}",
    require => File ["${installdir}"]
  }


  file { "${$installdir}":
    ensure  => directory
  }

}
