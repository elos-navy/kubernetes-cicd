#!/bin/bash -x

while [[ $# > 0 ]]
do
  KEY="$1"
  shift
  case "$KEY" in
    --user|-p)
      NEXUS_USER="$1"
      shift
      ;;
    --password|-u)
      NEXUS_PASSWORD="$1"
      shift
      ;;
    --url|-l)
      NEXUS_URL="$1"
      shift
      ;;
    *)
      echo "ERROR: Unknown argument '$KEY' to script '$0'" 1>&2
      exit -1
  esac
done


function add_api_script {
  PAYLOAD=$@

  curl -v \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -d "${PAYLOAD}" \
    -u "${NEXUS_USER}:${NEXUS_PASSWORD}" \
    "${NEXUS_URL}/service/rest/v1/script/"
}

function run_api_script {
  SCRIPT_NAME=$1

  curl -v \
    -X POST \
    -H "Content-Type: text/plain" \
    -u "${NEXUS_USER}:${NEXUS_PASSWORD}" \
    "${NEXUS_URL}/service/rest/v1/script/${SCRIPT_NAME}/run"
}

function create_docker_repo {
  NAME=$1
  PORT=$2

  read -r -d '' PAYLOAD <<- EOM
{
  "name": "$NAME",
  "type": "groovy",
  "content": "repository.createDockerHosted('$NAME',$PORT,null)"
}
EOM

  add_api_script $PAYLOAD
  run_api_script $NAME
}

function create_npm_proxy {
  NAME=$1
  URL=$2

  read -r -d '' PAYLOAD <<- EOM
{
  "name": "$NAME",
  "type": "groovy",
  "content": "repository.createNpmProxy('$NAME','$URL')"
}
EOM

  add_api_script $PAYLOAD
  run_api_script $NAME
}

function create_maven_proxy {
  NAME=$1
  URL=$2

  read -r -d '' PAYLOAD <<- EOM
{
  "name": "$NAME",
  "type": "groovy",
  "content": "repository.createMavenProxy('$NAME','$URL')"
}
EOM

  add_api_script $PAYLOAD
  run_api_script $NAME
}

function create_maven_group {
  NAME=$1
  REPOS=$2

  read -r -d '' PAYLOAD <<- EOM
{
  "name": "$NAME",
  "type": "groovy",
  "content": "repository.createMavenGroup('$NAME', '$REPOS'.split(',').toList())"
}
EOM

  add_api_script $PAYLOAD
  run_api_script $NAME
}

function create_release_repo {
  NAME=$1

  read -r -d '' PAYLOAD << EOM
{
  "name": "$NAME",
  "type": "groovy",
  "content": "import org.sonatype.nexus.blobstore.api.BlobStoreManager\nimport org.sonatype.nexus.repository.storage.WritePolicy\nimport org.sonatype.nexus.repository.maven.VersionPolicy\nimport org.sonatype.nexus.repository.maven.LayoutPolicy\nrepository.createMavenHosted('$NAME',BlobStoreManager.DEFAULT_BLOBSTORE_NAME, false, VersionPolicy.RELEASE, WritePolicy.ALLOW, LayoutPolicy.PERMISSIVE)"
}
EOM

  add_api_script $PAYLOAD
  run_api_script $NAME

}


# Red Hat Proxy Repos
#add_nexus3_proxy_repo redhat-ga https://maven.repository.redhat.com/ga/

#REPO_NAME='redhat-ga'
#REPO_URL='https://maven.repository.redhat.com/ga/'
create_maven_proxy redhat-ga https://maven.repository.redhat.com/ga/


# Repo Group to include all proxy repos
#add_nexus3_group_proxy_repo redhat-ga,maven-central,maven-releases,maven-snapshots maven-all-public
create_maven_group maven-all-public redhat-ga,maven-central,maven-releases,maven-snapshots


# NPM Proxy Repo
#add_nexus3_npmproxy_repo npm https://registry.npmjs.org/
create_npm_proxy npm https://registry.npmjs.org/

# Private Docker Registry
#add_nexus3_docker_repo docker 5000
create_docker_repo docker 5000

# Maven release Repo
#add_nexus3_release_repo releases
create_release_repo releases
