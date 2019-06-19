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

#
# Add a NPM Proxy Repo to Nexus3
# add_nexus3_proxy_repo [repo-id] [repo-url] [nexus-username] [nexus-password] [nexus-url]
#
function add_nexus3_npmproxy_repo() {

  local _REPO_ID=$1
  local _REPO_URL=$2

  read -r -d '' _REPO_JSON << EOM
{
  "name": "$_REPO_ID",
  "type": "groovy",
  "content": "repository.createNpmProxy('$_REPO_ID','$_REPO_URL')"
}
EOM

#  curl -v -H "Accept: application/json" -H "Content-Type: application/json" -d "$_REPO_JSON" -u "$NEXUS_USER:$_NEXUS_PWD" "${_NEXUS_URL}/service/rest/v1/script/"
#  curl -v -X POST -H "Content-Type: text/plain" -u "$NEXUS_USER:$_NEXUS_PWD" "${_NEXUS_URL}/service/rest/v1/script/$_REPO_ID/run"

  add_api_script $_REPO_JSON
  run_api_script $_REPO_ID
}

#
# Add a Proxy Repo to Nexus3
# add_nexus3_proxy_repo [repo-id] [repo-url] [nexus-username] [nexus-password] [nexus-url]
#
function add_nexus3_proxy_repo() {
  local _REPO_ID=$1
  local _REPO_URL=$2

  read -r -d '' _REPO_JSON << EOM
{
  "name": "$_REPO_ID",
  "type": "groovy",
  "content": "repository.createMavenProxy('$_REPO_ID','$_REPO_URL')"
}
EOM

#  curl -v -H "Accept: application/json" -H "Content-Type: application/json" -d "$_REPO_JSON" -u "$NEXUS_USER:$_NEXUS_PWD" "${_NEXUS_URL}/service/rest/v1/script/"
#  curl -v -X POST -H "Content-Type: text/plain" -u "$NEXUS_USER:$_NEXUS_PWD" "${_NEXUS_URL}/service/rest/v1/script/$_REPO_ID/run"

  #run_nexus_api_script $_REPO_JSON $_REPO_ID

  add_api_script $_REPO_JSON
  run_api_script $_REPO_ID

}

#
# Add a Release Repo to Nexus3
# add_nexus3_release_repo [repo-id] [nexus-username] [nexus-password] [nexus-url]
#
function add_nexus3_release_repo() {
  local _REPO_ID=$1

  # Repository createMavenHosted(final String name,
  #                                final String blobStoreName,
  #                                final boolean strictContentTypeValidation,
  #                                final VersionPolicy versionPolicy,
  #                                final WritePolicy writePolicy,
  #                                final LayoutPolicy layoutPolicy);

  read -r -d '' _REPO_JSON << EOM
{
  "name": "$_REPO_ID",
  "type": "groovy",
  "content": "import org.sonatype.nexus.blobstore.api.BlobStoreManager\nimport org.sonatype.nexus.repository.storage.WritePolicy\nimport org.sonatype.nexus.repository.maven.VersionPolicy\nimport org.sonatype.nexus.repository.maven.LayoutPolicy\nrepository.createMavenHosted('$_REPO_ID',BlobStoreManager.DEFAULT_BLOBSTORE_NAME, false, VersionPolicy.RELEASE, WritePolicy.ALLOW, LayoutPolicy.PERMISSIVE)"
}
EOM

#  curl -v -H "Accept: application/json" -H "Content-Type: application/json" -d "$_REPO_JSON" -u "$NEXUS_USER:$_NEXUS_PWD" "${_NEXUS_URL}/service/rest/v1/script/"
#  curl -v -X POST -H "Content-Type: text/plain" -u "$NEXUS_USER:$_NEXUS_PWD" "${_NEXUS_URL}/service/rest/v1/script/$_REPO_ID/run"

  #run_nexus_api_script $_REPO_JSON $_REPO_ID
  add_api_script $_REPO_JSON
  run_api_script $_REPO_ID

}

#
# add_nexus3_group_proxy_repo [comma-separated-repo-ids] [group-id] [nexus-username] [nexus-password] [nexus-url]
#
function add_nexus3_group_proxy_repo() {
  local _REPO_IDS=$1
  local _GROUP_ID=$2

  read -r -d '' _REPO_JSON << EOM
{
  "name": "$_GROUP_ID",
  "type": "groovy",
  "content": "repository.createMavenGroup('$_GROUP_ID', '$_REPO_IDS'.split(',').toList())"
}
EOM

#  curl -v -H "Accept: application/json" -H "Content-Type: application/json" -d "$_REPO_JSON" -u "$NEXUS_USER:$_NEXUS_PWD" "${_NEXUS_URL}/service/rest/v1/script/"
#  curl -v -X POST -H "Content-Type: text/plain" -u "$NEXUS_USER:$_NEXUS_PWD" "${_NEXUS_URL}/service/rest/v1/script/$_GROUP_ID/run"

  #run_nexus_api_script $_REPO_JSON $_GROUP_ID
  add_api_script $_REPO_JSON
  run_api_script $_GROUP_ID

}

#
# Add a Docker Registry Repo to Nexus3
# add_nexus3_docker_repo [repo-id] [repo-port] [nexus-username] [nexus-password] [nexus-url]
#
function add_nexus3_docker_repo() {
  local _REPO_ID=$1
  local _REPO_PORT=$2

  read -r -d '' _REPO_JSON << EOM
{
  "name": "$_REPO_ID",
  "type": "groovy",
  "content": "repository.createDockerHosted('$_REPO_ID',$_REPO_PORT,null)"
}
EOM

#  curl -v -H "Accept: application/json" -H "Content-Type: application/json" -d "$_REPO_JSON" -u "$NEXUS_USER:$_NEXUS_PWD" "${_NEXUS_URL}/service/rest/v1/script/"
#  curl -v -X POST -H "Content-Type: text/plain" -u "$NEXUS_USER:$_NEXUS_PWD" "${_NEXUS_URL}/service/rest/v1/script/$_REPO_ID/run"

  #run_nexus_api_script $_REPO_JSON $_REPO_ID
  add_api_script $_REPO_JSON
  run_api_script $_REPO_ID

}

# Main body of the script
# $1: Nexus3 User ID
# $2: Nexus3 Password
# $3: Nexus3 URL

# Red Hat Proxy Repos
add_nexus3_proxy_repo redhat-ga https://maven.repository.redhat.com/ga/
#add_nexus3_proxy_repo jboss https://repository.jboss.org/nexus/content/groups/public/ $1 $2 $3

# Repo Group to include all proxy repos
#add_nexus3_group_proxy_repo redhat-ga,jboss,maven-central,maven-releases,maven-snapshots maven-all-public $1 $2 $3
add_nexus3_group_proxy_repo redhat-ga,maven-central,maven-releases,maven-snapshots maven-all-public $1 $2 $3

# NPM Proxy Repo
add_nexus3_npmproxy_repo npm https://registry.npmjs.org/
# Private Docker Registry
add_nexus3_docker_repo docker 5000

# Maven release Repo
add_nexus3_release_repo releases
