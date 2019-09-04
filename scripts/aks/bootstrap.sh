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
    --git_branch)
      GIT_BRANCH="$1"
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
handle_error "Unable to login with service principal credentials!"

az account set --subscription "$SUBSCRIPTION_ID"
handle_error "Unable to set to subscription ${SUBSCRIPTION_ID}"

az aks get-credentials \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${CLUSTER_NAME}" \
  --admin
handle_error "Unable to set credentials!"

kubectl get nodes
handle_error "kubectl not configured correctly. Not connected to cluster!"

install_helm
install_ingress_controller
install_cert_manager

# Enable App routing addon and obtain DNS zone name.
# Store zone name for command to return it to ARM deployment output.
azure_enable_application_routing_addon
echo $DNS_ZONE_NAME > /http_application_routing_zone

# Jenkins Namespace
#create_from_template templates/jenkins-namespace.yaml \
#  _PREFIX_ $PREFIX
kubectl create ns $JENKINS_NAMESPACE
kubectl config set-context $(kubectl config current-context) --namespace=$JENKINS_NAMESPACE

# Create secret containing jenkins admin password.
#SECRET_FILE="$(mktemp -d)/password"
#echo -n $JENKINS_ADMIN_PASSWORD > $SECRET_FILE
#kubectl create secret generic $JENKINS_ADMIN_PASSWORD_SECRET_NAME \
#  --from-file=$SECRET_FILE
#rm -f $SECRET_FILE

# ACR credentials and hostname are used with jenkins/pipeline deployment
# and later for building jenkins agent container image.
REGISTRY_CREDENTIALS=$(az acr credential show -n $REGISTRY_NAME)
REGISTRY_USERNAME=$(echo $REGISTRY_CREDENTIALS | jq '.username' | sed 's/"//g')
REGISTRY_PASSWORD=$(echo $REGISTRY_CREDENTIALS | jq '.passwords[0].value' | sed 's/"//g')
REGISTRY_HOSTNAME=$(az acr show -n $REGISTRY_NAME | jq '.loginServer' | sed 's/"//g')

# Create k8s secret for pulling images from ACR registry.
#kubectl create secret docker-registry $REGISTRY_SECRET_NAME \
#    --docker-server=$ACR_HOSTNAME \
#    --docker-username=$ACR_USERNAME \
#    --docker-password=$ACR_PASSWORD \
#    --docker-email='info@elostech.cz'

# Jenkins
#create_from_template templates/jenkins-persistent.yaml \
#  _PREFIX_ "$PREFIX" \
#  _APPLICATION_GIT_URL_ "$APPLICATION_GIT_URL" \
#  _REGISTRY_HOSTNAME_ "$ACR_HOSTNAME" \
#  _REGISTRY_SECRET_NAME_ "$REGISTRY_SECRET_NAME" \
#  _JENKINS_ADMIN_PASSWORD_SECRET_ "$JENKINS_ADMIN_PASSWORD_SECRET_NAME" \
#  _COMPONENTS_PIPELINE_JOB_NAME_ 'cicd-components-pipeline' \
#  _APP_PIPELINE_JOB_NAME_ 'cicd-app-pipeline' \
#  _DNS_ZONE_NAME_ "$DNS_ZONE_NAME"
cd templates/helm
helm install \
  --name "$JENKINS_RESOURCE_NAME" \
  --namespace "$JENKINS_NAMESPACE" \
  --set name="$JENKINS_RESOURCE_NAME" \
  --set containerRegistry.hostname="$REGISTRY_HOSTNAME" \
  --set containerRegistry.secretName="$REGISTRY_SECRET_NAME" \
  --set containerRegistry.username="$REGISTRY_USERNAME" \
  --set containerRegistry.password="$REGISTRY_PASSWORD" \
  --set application.gitUrl="$APPLICATION_GIT_URL" \
  --set dnsDomain="$DNS_ZONE_NAME" \
  --set master.adminPassword="$JENKINS_ADMIN_PASSWORD" \
  jenkins
handle_error "Error while installing jenkins helm chart!"
cd -

# Build and push jenkins agent container images to ACR registry.
az acr build \
  -t ${JENKINS_NAMESPACE}/jenkins-agent:latest \
  -r $REGISTRY_NAME \
  artefacts/jenkins-agent/

az acr build \
  -t ${JENKINS_NAMESPACE}/jenkins-agent-maven:latest \
  -r $REGISTRY_NAME \
  artefacts/jenkins-agent-maven/

#create_from_template templates/ingress/tls-ingress.yaml \
#  _RESOURCE_NAME_ 'jenkins' \
#  _DNS_NAME_ "jenkins.$DNS_ZONE_NAME" \
#  _NAMESPACE_ "${PREFIX}jenkins" \
#  _SERVICE_NAME_ "${PREFIX}jenkins" \
#  _SERVICE_PORT_ 8080

# Setup wildcard DNS record for apps. This uses domain provided
# by HTTP Application Routing AKS addon enabled above.
wait_for_ingress_controller_public_ip
aazure_setup_dns_record $DNS_ZONE_NAME '*' "$ROUTER_IP"

# Wait for jenkins pod to be ready. So after ARM deployment jenkins
# should be ready and available.
#wait_for_deployment_ready "${PREFIX}jenkins" "app=${PREFIX}jenkins"
wait_for_deployment_ready "$JENKINS_NAMESPACE" "app=$JENKINS_RESOURCE_NAME"

# Cluster issuer can be created some time after cert-manager is installed.
# Do it as a last step of whole bootstrap, so there is no need to wait for
# it before.
create_cluster_issuer

rm -rf $TMP_DIR
