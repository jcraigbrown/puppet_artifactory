# Resource: artifactory::artifact
#
# This resource downloads Maven Artifacts from Artifactory
#
# Parameters:
# [*gav*] : The artifact groupid:artifactid:version (mandatory)
# [*packaging*] : The packaging type (jar by default)
# [*classifier*] : The classifier (no classifier by default)
# [*repository*] : The repository such as 'public', 'central'...
# [*output*] : The output file (mandatory)
# [*ensure*] : If 'present' checks the existence of the output file (and downloads it if needed), if 'absent' deletes the output file, if not set redownload the artifact
#
# Actions:
# If repository is set, its setting will be honoured.
# If repository is not set, its value is derived from the version contained in *gav*.  If the *gav* version is a SNAPSHOT then the repository will be set to 'snapshots', otherwise it will be 'releases'.
# If ensure is set to 'present' the resource checks the existence of the file and download the artifact if needed.
# If ensure is set to 'absent' the resource deleted the output file.
# If ensure is not set or set to 'update', the artifact is re-downloaded.
#
# Sample Usage:
#  class artifactory {
#   url => http://edge.spree.de/artifactory,
#   username => user,
#   password => password
# }
#
define artifactory::artifact(
  $gav,
  $packaging = 'jar',
  $classifier = '',
  $repository = '',
  $output,
  $ensure = update
  ) {
	
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

  $cmd = "/opt/artifactory-script/download-artifact-from-artifactory.sh -a ${gav} -e ${packaging} ${$includeClass} -n ${artifactory::ARTIFACTORY_URL} ${includeRepo} -o ${output} $args -v"
	
  if $ensure == present {
    exec { "Download ${gav}-${classifier}":
      command => $cmd,
      unless  => "test -f ${output}"
    }
  } elsif $ensure == absent {
    file { "Remove ${gav}-${classifier}":
      path   => $output,
      ensure => absent
    }
  } else {
    exec { "Download ${gav}-${classifier}":
      command => $cmd,
    }
  }
}
