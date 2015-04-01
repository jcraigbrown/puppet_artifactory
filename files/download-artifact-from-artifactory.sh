#!/bin/bash

# Define Artifactory Configuration
ARTIFACTORY_BASE=
URL_BASE=

usage()
{
    cat <<EOF

usage: $0 options

This script will fetch an artifact from a Artifactory server using the Artifactory REST redirect service.

OPTIONS:
   -h    Show this message
   -v    Verbose
   -t    Timestamped SNAPSHOTs
   -a    GAV coordinate groupId:artifactId:version
   -c    Artifact Classifier
   -e    Artifact Packaging
   -o    Output file
   -r    Repository
   -u    Username
   -p    Password
   -n    Artifactory Base URL

EOF
}

function artifact_target_name()
{
    local __artifact=$1
    local __version=$2
    local __packaging=$3
    local __classifier=$4
    local __target="${__artifact}-${__version}"

    if [[ ${__classifier} != "" ]]
    then
        __target="${__target}-${__classifier}"
    fi
    __target="${__target}.${__packaging}"

    echo "${__target}"
}

function artifact_source_name()
{
    local __artifact_base_url=$1
    local __artifact=$2
    local __snapshot=$3
    local __packaging=$4
    local __classifier=$5

    # Strip -SNAPSHOT from version
    local __version=`echo ${__snapshot} | sed -e "s/-SNAPSHOT//"`
    local __source="${__artifact}-${__version}"

    get_timestamp_and_build timestamp build ${__artifact_base_url}
    __source="${__source}-${timestamp}-${build}"

    if [[ ${__classifier} != "" ]]
    then
        __source="${__source}-${__classifier}"
    fi
    __source="${__source}.${__packaging}"

    echo "${__source}"
}

# Extract timestamp and build from maven-metadata.xml
function get_timestamp_and_build()
{
    local __timestamp_result=$1
    local __build_result=$2
    local __request_url=$3/maven-metadata.xml
    local __maven_metadata="/tmp/maven-metadata-$$.xml"
    local __ts=
    local __build=

    # Retrieve the maven-metadata.xml file
    curl -sS -f -L ${__request_url} -o ${__maven_metadata} ${CURL_VERBOSE} --location-trusted
    # Command to extract the timestamp
    __ts=`cat ${__maven_metadata} | tr -d [:space:] | grep -o "<timestamp>.*</timestamp>" \
        | tr '<>' '  ' | awk '{ print $2 }'`
    # Command to extract the build number
    __build=`cat ${__maven_metadata} | tr -d [:space:] | grep -o "<buildNumber>.*</buildNumber>" \
        | tr '<>' '  ' | awk '{ print $2 }'`
    # Remove the maven-metadata.xml file
    #rm ${__maven_metadata}

    eval ${__timestamp_result}="'${__ts}'"
    eval ${__build_result}="'${__build}'"
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
VERBOSE=0
TIMESTAMPED_SNAPSHOT=0

OUTPUT=

while getopts "hvta:c:e:o:r:u:p:n:b:" OPTION
do
    case $OPTION in
        h)
            usage
            exit 1
            ;;
        a)
            OIFS=$IFS
            IFS=":"
            GAV_COORD=( $OPTARG )
            GROUP_ID=`echo ${GAV_COORD[0]} | tr . /`
            ARTIFACT_ID=${GAV_COORD[1]}
            VERSION=${GAV_COORD[2]}
            IFS=$OIFS
            ;;
        c)
            CLASSIFIER=$OPTARG
            ;;
        e)
            PACKAGING=$OPTARG
            ;;
        v)
            VERBOSE=1
            ;;
        t)
            TIMESTAMPED_SNAPSHOT=1
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
        b)
            URL_BASE=$OPTARG
            ;;
        ?)
            echo "Illegal argument $OPTION=$OPTARG" >&2
            usage
            exit
            ;;
    esac
done

if [[ ${VERBOSE} -eq 0 ]]
then
    CURL_VERBOSE=""
else
    CURL_VERBOSE="-v"
fi

if [[ -z $GROUP_ID ]] || [[ -z $ARTIFACT_ID ]] || [[ -z $VERSION ]]
then
    echo "BAD ARGUMENTS: Either groupId, artifactId, or version was not supplied" >&2
    usage
    exit 1
fi

# Define default values for optional components

# If we don't have set a repository and the version requested is a SNAPSHOT use snapshots, otherwise use releases
if [[ "$REPOSITORY" == "" ]]
then
    if [[ "$VERSION" =~ "SNAPSHOT" ]]
    then
        if [[ ${VERBOSE} -ne 0 ]]
        then
            echo "Setting REPO to snapshots"
        fi
        : ${REPO:="snapshots"}
    else
        if [[ ${VERBOSE} -ne 0 ]]
        then
            echo "Setting REPO to releases"
        fi
        : ${REPO:="releases"}
    fi
fi

# Construct the base URL
ARTIFACT_BASE_URL=${ARTIFACTORY_BASE}${URL_BASE}/${REPO}/${GROUP_ID}/${ARTIFACT_ID}/${VERSION}
ARTIFACT_TARGET_NAME=$( artifact_target_name ${ARTIFACT_ID} ${VERSION} ${PACKAGING} ${CLASSIFIER} )

if [[ "${VERSION}" =~ "SNAPSHOT" ]] && [[ ${TIMESTAMPED_SNAPSHOT} -ne 0 ]]
then
    ARTIFACT_SOURCE_NAME=$( artifact_source_name ${ARTIFACT_BASE_URL} ${ARTIFACT_ID} ${VERSION} ${PACKAGING} ${CLASSIFIER} )
else
    ARTIFACT_SOURCE_NAME=${ARTIFACT_TARGET_NAME}
fi

if [[ ${VERBOSE} -ne 0 ]]
then
    echo "Base URL: ${ARTIFACT_BASE_URL}"
    echo "Artifact Target: ${ARTIFACT_TARGET_NAME}"
    echo "Artifact Source: ${ARTIFACT_SOURCE_NAME}"
fi

REQUEST_URL="${ARTIFACT_BASE_URL}/${ARTIFACT_SOURCE_NAME}"

# Authentication
AUTHENTICATION=
if [[ "$USERNAME" != "" ]]  && [[ "$PASSWORD" != "" ]]
then
    AUTHENTICATION="-u $USERNAME:$PASSWORD"
fi

# Output
OUT=
if [[ "$OUTPUT" != "" ]]
then
    OUT="-o $OUTPUT"
else
    OUT="-o ${ARTIFACT_TARGET_NAME}"
fi

echo "Fetching Artifact from $REQUEST_URL..." >&2
curl -sS -f -L ${REQUEST_URL} ${OUT} ${AUTHENTICATION} ${CURL_VERBOSE} --location-trusted
