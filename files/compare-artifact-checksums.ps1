<#
.SYNOPSIS
    Compare a file on the file system with a file (an artifact) in Artifactory.
    The comparison is done with MD5 checksums.

    The script will return with exit code 0 if the file on the file system
    has the same MD5 checksum as in Artifatory.

    The script will return with exit code 1 if the MD5 checksums differ or
    if an error occurred.
    
.DESCRIPTION
   download-artifact-from-artifactory.ps1 [-h]
   download-artifact-from-artifactory.ps1 [-v] [-t] -a <groupId:artifactId:version> [-c <classifier>] [-e <packaging>] [-o <outfile>] [-r <repository>] [-u <username>] [-p password] [-n <baseURL>]
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

function md5sum {
    param ( $_filename )
 
    $algo   = [System.Security.Cryptography.HashAlgorithm]::Create("MD5")
    $stream = New-Object System.IO.FileStream($_filename, [System.IO.FileMode]::Open)
 
    [string]$sum = -join ($algo.ComputeHash($stream) | % { "{0:x2}" -f $_ } )
 
    $stream.Dispose()

    return $sum
}


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
$artifact_api_base_url = "${n_baseurl}/api/storage/${repo}/${groupid}/${artifactid}/${version}"
$artifact_base_url     = "${n_baseurl}/${repo}/${groupid}/${artifactid}/${version}"

if ($classifier) {
    $artifact_target_name = "${artifactid}-${version}-${classifier}.${e_packaging}"
} else {
    $artifact_target_name = "${artifactid}-${version}.${e_packaging}"
}

if ("${version}" -match "snapshot" -and ${timestamped_snapshot}) {
    # TODO: Add support for timestamped snapshot
    write-error "Option 'timestamped_snapshot' was specified, but this module does not yet support that feature on Windows"
    exit 1
} else {
    $artifact_source_name=${artifact_target_name}
}

if ($username -and $password) {
    # TODO: Add support for authentication
    write-error "Username and password was specified, but this module does not yet support that feature on Windows"
    exit 1
}

$fileinfo_request_url = "${artifact_api_base_url}/${artifact_source_name}"

if ($output) {
    $localfile = "$output"
} else {
    $localfile = "${artifact_target_name}"
}

write-verbose  "Base API URL:         ${artifact_api_base_url}"
write-verbose  "Artifact Target:      ${artifact_target_name}"
write-verbose  "Artifact Source:      ${artifact_source_name}"
write-verbose  "Fileinfo request URL: ${fileinfo_request_url}"
write-verbose  "Local file:           ${localfile}"


try {
    # This will disable ssl certificate check, which is generally dangerous, but useful
    # if your artifactory server is on https with a self-signed certificate.
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

    $wc = New-Object System.Net.WebClient
    $md5_checksum_repo = ($wc.DownloadString("${fileinfo_request_url}") | ConvertFrom-Json).checksums.md5

}
catch {
    write-error ("Fetching checksum FAILED! An exception occured while trying to fetch:`n" + $_.Exception.ToString())
    exit 1
}
finally {
    # Restore default ssl security settings
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {}
}


$md5_checksum_file = md5sum $localfile
write-verbose "Comparing checksums:"
write-verbose "from repo: ${md5_checksum_repo}"
write-verbose "from file: ${md5_checksum_file}"

if ( "$md5_checksum_repo" -eq "$md5_checksum_file" ) {
    write-verbose "Checksums from repository and local file are identical"
    exit 0
} else {
    write-verbose "Checksum from repository: ""${md5_checksum_repo}"" differ from checksum of local file: ""${md5_checksum_file}"""
    exit 1
}
