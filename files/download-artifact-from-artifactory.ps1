<#
.SYNOPSIS
    Download artifact from Artifactory.
    
.DESCRIPTION
   download-artifact-from-artifactory.ps1 [-h]
   download-artifact-from-artifactory.ps1 [-v] [-t] -a <groupId:artifactId:version> [-c <classifier>] [-e <packaging>] [-o <outfile>] [-r <repository>] [-u <username>] [-p password] [-n <baseURL>]

.PARAMETER -h
        show help.
        
.PARAMETER -v
        Verbose output.
 
.PARAMETER -n
        Base URL of artifactory.
		Note: include '/artifactory' at the end, if artifactory is available under that location. (Earlier versions
		of the puppet module always appended this. That is no longer the case).
 
    
.NOTES    
    
.EXAMPLE
        
        download-artifact-from-artifactory.ps1 -a ...
    
    Description
    -----------
    Downloads ....
        
#>


param(
    [switch]$help,
    [switch]$verbose,
    [switch]$timestamped_snapshot, 
    [string]$artifactGAV,
    [string]$classifier,
    [string]$e_packaging='jar',
    [string]$output,
    [string]$repo,
    [string]$username,
    [string]$password,
	[string]$n_baseurl
)


if ($help) {
	get-help $MyInvocation.MyCommand.Definition
    exit 0
}

if ($verbose) {
    $VerbosePreference = "Continue"
    $curl_verbose='-v'
}

($groupid, $artifactid, $version) = $artifactGAV.split(':')
$groupid = $groupid.Replace('.','/')

if (!$groupid -or !$artifactid -or !$version) {
	write-error "BAD ARGUMENTS: Either groupId, artifactId, or version was not supplied"
	get-help $MyInvocation.MyCommand.Definition
    exit 1
}

if (!$repo) {
    if ($version -match "snapshot") {
		$repo = "snapshots"
	} else {
		$repo = "releases"
	}
}

# Construct the base URL
$artifact_base_url    = "${n_baseurl}/${repo}/${groupid}/${artifactid}/${version}"
if ($classifier) {
	$artifact_target_name = "${artifactid}-${version}-${classifier}.${e_packaging}"
} else {
	$artifact_target_name = "${artifactid}-${version}.${e_packaging}"
}

if ("${version}" -match "snapshot" -and ${timestamped_snapshot}) {
    # TODO: support for timestamped snapshot
    write-error "WARNING: Option 'timestamped_snapshot' was specified, but that feature is not yet supported in this script!"
} else {
    $artifact_source_name=${artifact_target_name}
}

if ($username -and $password) {
	# TODO: support for authentication
    write-error "WARNING: Username and password was specified, but authenticated access is not yet supported in this script!"
}

$request_url = "${artifact_base_url}/${artifact_source_name}"

if ($output) {
    $out = "$output"
} else {
    $out = "${artifact_target_name}"
}

write-verbose  "Base URL:        ${artifact_base_url}"
write-verbose  "Artifact Target: ${artifact_target_name}"
write-verbose  "Artifact Source: ${artifact_source_name}"
write-verbose  "request URL:     ${request_url}"
write-verbose  "Output file:     ${out}"

try {
	# This will disable ssl certificate check, which is generally dangerous, but useful
	# if your artifactory server is on https with a self-signed certificate.
	[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

	$wc = New-Object System.Net.WebClient
	$wc.DownloadFile("${request_url}", "$out")
}
catch {
	write-error ("DOWNLOAD FAILED! An exception occured while trying to download:`n" + $_.Exception.ToString())
	exit 1
}
finally {
	# Restore default ssl security settings
	[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {}
}