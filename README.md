Puppet Module for Artifactory
=============================

A Puppet module which downloads artifacts from an Artifactory repository.

It supports:

* artifact identification using GAV, classifier, and packaging
* repository selection
* timestamped SNAPSHOTs (not on Windows)

It relies on the Artifactory REST service, bash, and curl.

This module is based on the [Puppet Nexus module](https://github.com/cescoffier/puppet-nexus)
authored by Clement Escoffier.

Getting the Module
------------------

* Retrieve it from Puppet Forge.

	puppet module install jcraigbrown-artifactory

* Clone this repository and add it to your _modulepath_

Usage
-----

Initialize the Puppet Artifactory module and specify the URL of your artifactory
system. Note that previous versions of this module automatically appended
'/artifactory' to this URL. This is no longer the case, so make sure the
specified URL includes '/artifactory', if required.

	class {'artifactory':
	  url => 'http://artifactory.domain.com',
	}

Examples of downloading artifacts:

	artifactory::artifact {'commons-io':
	  gav        => 'commons-io:commons-io:2.1',
	  repository => 'public',
	  output     => '/tmp/commons-io-2.1.jar',
	}

	artifactory::artifact {'/tmp/ipojo.jar':
	  gav => 'org.apache.felix:org.apache.felix.ipojo:1.8.0',
	}

	artifactory::artifact {'/tmp/parser-0.3.0-SNAPSHOT.jar':
	  gav         => 'com.company.project:parser:0.3.0-SNAPSHOT',
	  timestamped => true,
	}

	artifactory::artifact {'chameleon web distribution':
	  gav => 'org.ow2.chameleon:distribution-web:0.3.0-SNAPSHOT',
	  classifier => 'distribution',
	  packaging  => 'zip',
	  repository => 'public-snapshots',
	  output     => '/tmp/distribution-web-0.3.0-SNAPSHOT.zip'
	}


License
-------

This project is licensed under the Apache License, Version 2.0.

