# Kubernetes CI/CD ELOS project

Scripts and templates for CI/CD project deployment.

## Azure AKS

### Deployment via service order

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Felos-tech%2Fkubernetes-cicd%2Fmaster%2Fazure%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Felos-tech%2Fkubernetes-cicd%2Fmaster%2Fazure%2Fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

#### Prerequisites

* Application registration (service principal) + role asiignement. Form accepts ID and secret key of application registration in AD. How to register new application: https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal

#### Troubleshooting

##### Supported version of kubernetes

Deployment can end up with following error: 'The value of parameter orchestratorProfile.OrchestratorVersion is invalid'. Then it is needed to find out supported version of kubernetes:

```
az aks get-versions --location westeurope --output table
```

And this version to enter into form and update ARM template. Supported versions are changing over time!

### Manually created cluster

#### Prerequisites

* Azure CLI (`az` command) and `jq` package/command.
* Login to Azure with `az login` command.
* Commands in this README should be executed in root directory of this GIT repo clone.

#### Configuration

Setup names of resource groups, cluster, registry to your needs. Or leave it as it is, but no other resources with the same name should exist.

```
vim scripts/config
```

#### Create AKS cluster

```
./scripts/aks/manage_cluster.sh create_rg
./scripts/aks/manage_cluster.sh create_cluster
./scripts/aks/manage_cluster.sh create_acr
./scripts/aks/manage_cluster.sh setup_credentials
```

#### Remove AKS cluster

```
./scripts/aks/manage_cluster.sh delete_cluster
./scripts/aks/manage_cluster.sh delete_acr
./scripts/aks/manage_cluster.sh delete_rg
```

#### Create Jenkins

TODO

#### Jenkins login

Get public IP address of jenkins service:

```
kubectl get svc cicd-jenkins
```

In `EXTERNAL-IP` columnt, there is an IP address accessible via web browser on port 8080.


#### Removal of jenkins components

TODO
