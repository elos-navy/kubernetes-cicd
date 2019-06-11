#!/bin/bash

source ./scripts/config
source ./scripts/functions

TMP_DIR=$(mktemp -d)

while [[ $# > 0 ]]
do
  KEY="$1"
  shift
  case "$KEY" in
    --app_id|-ai)
      APP_ID="$1"
      shift
      ;;
    --app_key|-ak)
      APP_KEY="$1"
      shift
      ;;
    --subscription_id|-si)
      SUBSCRIPTION_ID="$1"
      shift
      ;;
    --tenant_id|-ti)
      TENANT_ID="$1"
      shift
      ;;
    --resource_group|-rg)
      RESOURCE_GROUP="$1"
      shift
      ;;
    --cluster_name|-an)
      CLUSTER_NAME="$1"
      shift
      ;;
    --jenkins_admin_password)
      JENKINS_ADMIN_PASSWORD="$1"
      shift
      ;;
    --application_git_url)
      APPLICATION_GIT_URL="$1"
      shift
      ;;
    --registry_name)
      REGISTRY_NAME="$1"
      shift
      ;;
    --location)
      LOCATION="$1"
      shift
      ;;
    *)
      echo "ERROR: Unknown argument '$KEY' to script '$0'" 1>&2
      exit -1
  esac
done

set -x

install_kubectl
install_az
sudo apt-get install --yes jq

az login --service-principal -u "$APP_ID" -p "$APP_KEY" -t "$TENANT_ID"
az account set --subscription "$SUBSCRIPTION_ID"
az aks get-credentials --resource-group "${RESOURCE_GROUP}" --name "${CLUSTER_NAME}" --admin

kubectl get nodes || {
  echo "Error: kubectl not configured correctly. Not connected to cluster!"
  exit 0
}

install_helm
install_ingress_controller
install_cert_manager

enable_application_routing_addon

# Store zone name for command to return it to ARM deployment output.
echo $DNS_ZONE_NAME > /http_application_routing_zone


# Jenkins Namespace
create_from_template templates/jenkins-namespace.yaml \
  _PREFIX_ $PREFIX
kubectl config set-context $(kubectl config current-context) --namespace=${PREFIX}jenkins

# Jenkins
create_from_template templates/jenkins-persistent.yaml \
  _PREFIX_ $PREFIX \
  _JENKINS_ADMIN_PASSWORD_ "$JENKINS_ADMIN_PASSWORD" \
  _APPLICATION_GIT_URL_ "$APPLICATION_GIT_URL" \
  _REGISTRY_NAME_ "$REGISTRY_NAME" \
  _REGISTRY_SECRET_NAME_ "$REGISTRY_SECRET_NAME" \
  _COMPONENTS_PIPELINE_JOB_NAME_ 'cicd-components-pipeline' \
  _APP_PIPELINE_JOB_NAME_ 'cicd-app-pipeline' \
  _DNS_ZONE_NAME_ "$DNS_ZONE_NAME"

# Build and push Jenkins agent POD to ACR registry
az acr build -t ${PREFIX}jenkins/jenkins-agent-appdev:latest -r $REGISTRY_NAME artefacts/

# Set k8s secret for pulling images from ACR registry
ACR_CREDENTIALS=$(az acr credential show -n $REGISTRY_NAME)
ACR_USERNAME=$(echo $ACR_CREDENTIALS | jq '.username' | sed 's/"//g')
ACR_PASSWORD=$(echo $ACR_CREDENTIALS | jq '.passwords[0].value' | sed 's/"//g')
ACR_HOSTNAME=$(az acr show -n $REGISTRY_NAME | jq '.loginServer' | sed 's/"//g')
kubectl create secret docker-registry $REGISTRY_SECRET_NAME \
    --docker-server=$ACR_HOSTNAME \
    --docker-username=$ACR_USERNAME \
    --docker-password=$ACR_PASSWORD \
    --docker-email='info@elostech.cz'

create_from_template templates/ingress/tls-ingress.yaml \
  _RESOURCE_NAME_ 'jenkins' \
  _DNS_NAME_ "jenkins.$DNS_ZONE_NAME" \
  _NAMESPACE_ "${PREFIX}jenkins" \
  _SERVICE_NAME_ "${PREFIX}jenkins" \
  _SERVICE_PORT_ 8080


wait_for_ingress_controller_public_ip
setup_dns_record $DNS_ZONE_NAME '*' "$ROUTER_IP"


rm -rf $TMP_DIR
