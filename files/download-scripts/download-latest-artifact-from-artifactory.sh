#!/bin/bash

usage()
{
    cat <<EOF

usage: $0 options

This script will fetch an artifact from a Artifactory server using the Artifactory REST redirect service.

OPTIONS:
   -h    Show this message
   -g    groupId
   -a    artifactId
   -e    Artifact Packaging
   -o    Output file
   -r    Repository
   -u    Username
   -p    Password
   -n    Artifactory Base URL

EOF
}

# Read in Complete Set of Coordinates from the Command Line
GROUP_ID=
ARTIFACT_ID=
VERSION=
CLASSIFIER=""
PACKAGING=jar
REPO=
USERNAME=
PASSWORD=
OUTPUT=

while getopts "ha:g:c:e:o:r:u:p:n:" OPTION
do
    case $OPTION in
        h)
            usage
            exit 1
            ;;
        a)
            ARTIFACT_ID=$OPTARG
            ;;
        g)
            GROUP_ID=$OPTARG
            ;;
        c)
            CLASSIFIER=$OPTARG
            ;;
        e)
            PACKAGING=$OPTARG
            ;;
        o)
            OUTPUT=$OPTARG
            ;;
        r)
            REPO=$OPTARG
            ;;
        u)
            USERNAME=$OPTARG
            ;;
        p)
            PASSWORD=$OPTARG
            ;;
        n)
            ARTIFACTORY_BASE=$OPTARG
            ;;
        ?)
            echo "Illegal argument $OPTION=$OPTARG" >&2
            usage
            exit
            ;;
    esac
done


sudo wget --user=${USERNAME} --password=${PASSWORD} -O ${OUTPUT} \
  ${ARTIFACTORY_BASE}/artifactory/${REPO}/${GROUP_ID}/${ARTIFACT_ID}/[RELEASE]/${ARTIFACT_ID}-[RELEASE]${PACKAGING}

