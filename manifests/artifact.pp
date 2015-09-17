# Resource: artifactory::artifact
#
# This resource downloads Maven Artifacts from Artifactory
#
# Parameters:
# [*ensure*] : If 'present' checks the existence of the output file (and downloads it if needed), if 'absent' deletes the output file, if not set redownload the artifact
# [*gav*] : The artifact groupid:artifactid:version (mandatory)
# [*packaging*] : The packaging type (jar by default)
# [*classifier*] : The classifier (no classifier by default)
# [*repository*] : The repository such as 'public', 'central'... (defaults to 'releases' or 'snapshots' depending on the version specified in gav
# [*output*] : The output file (defaults to the resource name)
#
# Actions:
# If repository is set, its setting will be honoured.
# If repository is not set, its value is derived from the version contained in *gav*.  If the *gav* version is a SNAPSHOT then the repository will be set to 'snapshots', otherwise it will be 'releases'.
# If ensure is set to 'present' the resource checks the existence of the file and download the artifact if needed.
# If ensure is set to 'absent' the resource deleted the output file.
# If ensure is not set or set to 'update', the artifact is re-downloaded.
#
# Sample Usage:
#   class artifactory {
#     url      => 'http://artifactory.domain.com:8081',
#     username => 'user',
#     password => 'password',
#   }
#
#   artifactory::artifact {'Zabbix JMX client':
#     ensure => present,
#     gav    => 'org.kjkoster:zapcat:1.2.8',
#     output => '/usr/share/java/zapcat.jar',
#   }
#
#   artifactory::artifact {'/usr/share/java/jna.jar':
#     ensure     => present,
#     repository => 'thirdparty-releases',
#     gav        => "net.java:jna:3.4.1",
#   }
#
#   artifactory::artifact {'/tmp/distribution.tar.gz':
#     ensure      => present,
#     gav         => 'com.domain.procect:distribution:0.9.2-SNAPSHOT',
#     packaging   => 'tar.gz',
#     timestamped => true,
#   }
#
define artifactory::artifact(
  $ensure = update,
  $gav = '',
  $groupId = '',
  $artifactId = '',
  $packaging = 'jar',
  $repository = '',
  $output = $name,
  $timestamped = false)
{

  include artifactory

  Exec { path => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'], }

  if ($artifactory::authentication) {
    $args = "-u ${artifactory::user} -p '${artifactory::pwd}'"
  } else {
    $args = ''
  }

  if ($classifier) {
    $includeClass = "-c ${classifier}"
  }

  if ($repository) {
    $includeRepo = "-r ${repository}"
  }

  if ($timestamped) {
    $timestampedRepo = "-t"
  }

  if ($gav != '') {
    $cmd = "/opt/artifactory-script/download-artifact-from-artifactory-via-gav.sh -a ${gav} -e ${packaging} ${includeClass} -n ${artifactory::artifactoryUrl} ${includeRepo} ${timestampedRepo} -o ${output} ${args} -v"
    $DownloadConsoleOutput = "Download ${gav}-${classifier} to ${output}"
    $RemovalConsoleOutput = "Remove ${gav}-${classifier} to ${output}"
  } else {
    $cmd = "/opt/artifactory-script/download-latest-artifact-from-artifactory.sh -g ${groupId} -a ${artifactId} -e ${packaging} -n ${artifactory::artifactoryUrl}${includeRepo} -o ${output} ${args}"
    $DownloadConsoleOutput = "Download latest${groupId}:${artifactId} to ${output}"
  }

  if $ensure == present {
    exec { $DownloadConsoleOutput :
      command => $cmd,
      unless  => "test -f ${output}"
    }
  } elsif $ensure == absent {
    file { $RemovalConsoleOutput :
      path   => $output,
      ensure => absent
    }
  } else {
    exec { $DownloadConsoleOutput :
      command => $cmd,
    }
  }
}
