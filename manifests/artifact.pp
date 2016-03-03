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
  $gav,
  $packaging = 'jar',
  $classifier = '',
  $repository = '',
  $output = $name,
  $timestamped = false)
{

  include artifactory


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

  $cmdargs = "-a ${gav} -e ${packaging} ${includeClass} -n ${artifactory::ARTIFACTORY_URL} ${includeRepo} ${timestampedRepo} -o ${output} ${args} -v"

  if $::operatingsystem == 'windows' {
    Exec { path => ['C:/Windows/System32', 'C:/Windows/System32/WindowsPowerShell/v1.0'], }
    $downloadcmd = "${artifactory::installdir}\\${artifactory::downloadscript} ${cmdargs}"
    $comparecmd  = "${artifactory::installdir}\\${artifactory::comparescript}  ${cmdargs}"
    $cmd         = "powershell -executionpolicy remotesigned -file ${downloadcmd}"
    $unlesscmd   = "powershell -executionpolicy remotesigned -file ${comparecmd}"
  } else {
    Exec { path => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'], }
    $downloadcmd = "${artifactory::installdir}/${artifactory::downloadscript} ${cmdargs}"
    $comparecmd  = "${artifactory::installdir}/${artifactory::comparescript}  ${cmdargs}"
    $cmd         = "${downloadcmd}"
    $unlesscmd   = "${comparecmd}"
  }

  if $ensure == present {
    exec { "Download ${gav}-${classifier} to ${output}":
      command => $cmd,
      unless  => $unlesscmd,
      require => File [
          "${artifactory::installdir}/${artifactory::comparescript}",
          "${artifactory::installdir}/${artifactory::downloadscript}"
      ],
    }
  } elsif $ensure == absent {
    file { "Remove ${gav}-${classifier} to ${output}":
      path   => $output,
      ensure => absent
    }
  } else {
    exec { "Download ${gav}-${classifier} to ${output}":
      command => $cmd,
      require => File [ "${artifactory::installdir}/${artifactory::downloadscript}" ],
    }
  }
}
