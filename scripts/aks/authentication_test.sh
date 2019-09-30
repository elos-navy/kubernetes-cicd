#!/bin/bash -x

CLUSTER_NAME='ls-auth-testing'
RESOURCE_GROUP=$CLUSTER_NAME
CLUSTER_LOCATION='westeurope'

function create_server_registration {
 
  # Create the Azure AD application
  SERVER_APP_ID=$(az ad app create \
    --display-name "${CLUSTER_NAME}-server" \
    --identifier-uris "https://${CLUSTER_NAME}-server" \
    --query appId \
    -o tsv)
  
  # Update the application group memebership claims
  az ad app update \
    --id $SERVER_APP_ID \
    --set groupMembershipClaims=All
  
  # Create a service principal for the Azure AD application
  az ad sp create --id $SERVER_APP_ID
  
  # Get the service principal secret
  SERVER_APP_SECRET=$(az ad sp credential reset \
    --name $SERVER_APP_ID \
    --credential-description "AKSPassword" \
    --query password \
    -o tsv)
  
  az ad app permission add \
    --id $SERVER_APP_ID \
    --api 00000003-0000-0000-c000-000000000000 \
    --api-permissions \
        e1fe6dd8-ba31-4d61-89e7-88639da4683d=Scope \
        06da0dbc-49e2-44d2-8312-53f166ab848a=Scope \
        7ab1d382-f21e-4acd-a863-ba3e13f7da61=Role
  
  az ad app permission grant \
    --id $SERVER_APP_ID \
    --api 00000003-0000-0000-c000-000000000000
  
  az ad app permission admin-consent \
    --id $SERVER_APP_ID
}

function create_client_registration {
  CLIENT_APP_ID=$(az ad app create \
    --display-name "${CLUSTER_NAME}-client" \
    --native-app \
    --reply-urls "https://${CLUSTER_NAME}-client" \
    --query appId -o tsv)
  
  az ad sp create --id $CLIENT_APP_ID
  
  OAUTH_PERMISSION_ID=$(az ad app show \
    --id $SERVER_APP_ID \
    --query "oauth2Permissions[0].id" \
    -o tsv)
  
  az ad app permission add \
    --id $CLIENT_APP_ID \
    --api $SERVER_APP_ID \
    --api-permissions $OAUTH_PERMISSION_ID=Scope

  az ad app permission grant \
    --id $CLIENT_APP_ID \
    --api $SERVER_APP_ID
}

function create_cluster {
  az group create \
    --name $RESOURCE_GROUP \
    --location $CLUSTER_LOCATION

  TENANT_ID=$(az account show --query tenantId -o tsv)

  az aks create \
    --resource-group $RESOURCE_GROUP \
    --name $CLUSTER_NAME \
    --node-count 1 \
    --generate-ssh-keys \
    --aad-server-app-id $SERVER_APP_ID \
    --aad-server-app-secret $SERVER_APP_SECRET \
    --aad-client-app-id $CLIENT_APP_ID \
    --aad-tenant-id $TENANT_ID

  az aks get-credentials --yes \
    --resource-group $RESOURCE_GROUP \
    --name $CLUSTER_NAME \
    --admin
}

function create_role_binding {
  USER_PRINCIPAL_NAME=$(az ad signed-in-user show --query userPrincipalName -o tsv)
  cat > /tmp/basic-azure-ad-binding.yaml << EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: contoso-cluster-admins
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: $USER_PRINCIPAL_NAME
EOF
  kubectl apply -f /tmp/basic-azure-ad-binding.yaml
}

function cleanup {
  az ad app delete --id "https://${CLUSTER_NAME}-server"
  az ad app delete --id "https://${CLUSTER_NAME}-client"

  az aks delete --yes \
    --resource-group $RESOURCE_GROUP \
    --name $CLUSTER_NAME
}


#create_server_registration
#create_client_registration
#create_cluster
#create_role_binding

#az aks get-credentials --yes \
#  --resource-group $RESOURCE_GROUP \
#  --name $CLUSTER_NAME \
#  --overwrite-existing

cleanup
