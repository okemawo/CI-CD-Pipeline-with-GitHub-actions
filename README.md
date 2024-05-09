# A Multicloud Miroservices Based CI/CD Pipeline Using Github actions

This project employs a Continuous Integration/Continuous Deployment (CI/CD) pipeline using GitHub Actions. The pipeline is defined in the `.github/workflows/cicd.yml` file.

![image](https://github.com/okemawo/CI-CD-Pipeline-with-GitHub-actions/assets/65502643/f31a5cfc-ef3f-4b7a-bbc0-41bbd54addcd)

Broadly the project is designed to deploy and scale three microservices. The table below shows a brief description of the table and also the paths as well as the ports specified for each of the mentioned service.

| Path     | Service Name           | Service Port |
|----------|------------------------|--------------|
| /chat    | spring-chat-service    | 80           |
| /login   | spring-login-service   | 80           |
| /profile | spring-profile-service | 80           |

- Profile Service
The profile service is a simple REST application that handles GET requests to fetch profile data from the database and responds in the JSON format. Each user profile object contains a username, name, gender, and age.

- Chat Service
The Chat service uses Redis’ PubSub to synchronize the chat messages among replicas as it can be easily deployed and managed in a Kubernetes cluster. The provided application uses MySQL to persist the chat messages, so that users don’t lose their chat history.

## Prerequisites

- [Google Cloud Platform (GCP) account](https://console.cloud.google.com/) created
- [Azure Cloud Platform Account](https://azure.microsoft.com/en-us/free/) created
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) installed
- [kubectl](https://kubernetes.io/docs/tasks/tools/) installed
- [Docker](https://www.docker.com/get-started) installed
- [maven](https://maven.apache.org/what-is-maven.html) installed
- [helm](https://helm.sh/docs/helm/helm_install/) installed

### Clone the Repository

```bash
git clone https://github.com/okemawo/CI-CD-Pipeline-with-GitHub-actions.git
```
<br>


### Login to docker hub 
- You will be promted to input your username and password or access token 
```bash
docker login
```
<br>

### Install Software Tools
- Docker
```bash
apt install docker.io
docker --version
```

- NodeJs and npm
```bash
apt install nodejs npm
```

- Maven
```bash
apt install maven
apt update
```
<br>

### CI-CD Workflow Overview

The workflow is activated on push events to the `main` branch and can also be manually triggered from the Actions tab.

The workflow is composed of several jobs:

1. **check-changed-files**: This job checks for any modifications in the source code of specific microservices (`/src/chat`, `/src/login`, `/src/profile`) and outputs the results (true if any changes).

2. **build-push-image**: This job builds and pushes Docker images for the microservices that have undergone changes. The images are tagged with the commit SHA and pushed to both Google Cloud Registry (GCR) and Azure Container Registry (ACR).

3. **deploy**: This job deploys the updated microservices to both Google Cloud Platform (GCP) and Azure.

### Environment Variables
The workflow uses several environment variables, which are defined in the `env` section of the `.github/workflows/cicd.yml` file. These include:

- `GCP_CLUSTER_NAME`: The name of the GCP cluster.
- `GCP_PROJECT_ID`: The ID of the GCP project.
- `GCP_REGION`: The GCP region.
- `AZ_CONTAINER_REGISTRY`: The Azure Container Registry.
- `AZ_CLUSTER_NAME`: The name of the Azure cluster.
- `AZ_RESOURCE_GROUP`: The Azure resource group.
- `DOCKER_TAG`: The Docker tag, which is set to the commit SHA.

### Docker Image Building

Docker images are built for each microservice that has changed. The Dockerfiles are located in the `src/{microservice}/main/docker` directory of each microservice. The images are tagged with the commit SHA and pushed to both GCR and ACR.

### Deployment

The deployment is done using Helm charts. The deployment files are updated to use the Docker images that were just pushed. The updated microservices are then deployed to both GCP and Azure.

### Azure and GCP Authentication

The workflow uses the `google-github-actions/auth` action to authenticate to Google Cloud, and the `azure/login` action to authenticate to Azure. The credentials for these services are stored as GitHub secrets.

# Deployment to GCP

## Create a Kubernetes cluster in GCP
Use the Googe Cloud SDK to create the cluster and retrieve the cluster credentials so you can access the cluster via kubectl.

- Set the cluster name, machine type and the zone
```bash
CLUSTER_NAME="chatcluster"
```

- Create the cluster
```bash
gcloud container clusters create $CLUSTER_NAME --zone=us-east1-d --num-nodes=1 --machine-type=n1-standard-4
```

- Get Cluster Context
```bash
gcloud container clusters get-credentials $CLUSTER_NAME --zone=us-east1-d
```

- Add helm repo
```bash
# Get the latest Chart information from chart repositories
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

## Create the Ingress Resource
- Create an NGINX ingress controller
```bash
helm install my-nginx bitnami/nginx-ingress-controller --version v9.3.24
```

- Create an Ingress resource
```
# Navigate to ``/Ingress`
cd Ingress_Azure

# Create resource
kubectl create -f ingress.yaml

# Check the state of the Ingress you just added with
kubectl get ingress
```

## Use Helm to deploy the Profile service to the GKE cluster
- Set the values of the environment variables
```bash
export mysqlRootPassword=<REPLACE WITH ROOT PASSWORD>
export mysqlUser=<REPLACE WITH USERNAME>
export mysqlPassword=<REPLACE WITH USER PASSWORD>
```

- Install the MySQL backend
```bash
helm install mysql-profile --set auth.rootPassword=${mysqlRootPassword},auth.username=${mysqlUser},auth.password=${mysqlPassword},auth.database=test bitnami/mysql --set image.debug=true \
--set primary.persistence.enabled=false,secondary.persistence.enabled=false \
--set primary.readinessProbe.enabled=false,primary.livenessProbe.enabled=false \
--set secondary.readinessProbe.enabled=false,secondary.livenessProbe.enabled=false
```

- Install the Profile service
```bash
# Install profile service
helm install profile profile-service/src/main/helm/profile/

# Validate the helm installation
helm list
```

## Use Helm to deploy the Chat service to the GKE cluster
- Set the values of the environment variables
```bash
export mysqlRootPassword=<REPLACE WITH ROOT PASSWORD>
export mysqlUser=<REPLACE WITH USERNAME>
export mysqlPassword=<REPLACE WITH USER PASSWORD>
```

- Install the MySQL backend
```bash
helm install chat --set auth.rootPassword=${mysqlRootPassword},auth.username=${mysqlUser},auth.password=${mysqlPassword},auth.database=test bitnami/mysql --set image.debug=true \
--set primary.persistence.enabled=false,secondary.persistence.enabled=false \
--set primary.readinessProbe.enabled=false,primary.livenessProbe.enabled=false \
--set secondary.readinessProbe.enabled=false,secondary.livenessProbe.enabled=false
```

- Install the Chat service
```bash
# Install group-chat service
helm install chat group-chat-service/src/main/helm/chat/

# Validate the helm installation
helm list
```

## Use Helm to deploy the Login service to the GKE cluster
- Set the values of the environment variables
```bash
export mysqlRootPassword=<REPLACE WITH ROOT PASSWORD>
export mysqlUser=<REPLACE WITH USERNAME>
export mysqlPassword=<REPLACE WITH USER PASSWORD>
```

- Install the MySQL backend
```bash
helm install login --set auth.rootPassword=${mysqlRootPassword},auth.username=${mysqlUser},auth.password=${mysqlPassword},auth.database=test bitnami/mysql --set image.debug=true \
--set primary.persistence.enabled=false,secondary.persistence.enabled=false \
--set primary.readinessProbe.enabled=false,primary.livenessProbe.enabled=false \
--set secondary.readinessProbe.enabled=false,secondary.livenessProbe.enabled=false
```

- Install the login service
```bash
# Install login service
helm install login login-service/src/main/helm/login/

# Validate the helm installation
helm list
```

# Deployment to AZURE
Once you have created the service on the GKE cluster, you will create an AKS cluster to implement a multi-cloud deployment. 
Here is a brief table that describes the services being deployed. As you might observe there is one less service here, as the chat service is being solely hosted on GCP because of constraints that may occur due to the CAPS theorem.

| Path     | Service Name           | Service Port |
|----------|------------------------|--------------|
| /login   | spring-login-service   | 80           |
| /profile | spring-profile-service | 80           |

## Create a Kubernetes cluster in Azure
Use the Azure CLI to create the cluster and retrieve the cluster credentials so you can access the cluster via kubectl.

- Login to AZURE
```bash
az login --use-device-code
```

- Check and set the Azure subscription
```bash
az account list --output table --refresh
az account set --subscription <name or id>
```

- Initialize variable
```bash
# Cluster name
export CLUSTER_NAME="chatcluster"

# Container registry name
export ACR_NAME=<set a name>

# Resource Group name
export export RESOURCE_GROUP=<set resource group name>
```

- Create the cluster, resource group and ACR
```bash
# Resource group
az group create -n ${RESOURCE_GROUP} -l eastus

# Container registry
az acr create -n ${ACR_NAME} -g ${RESOURCE_GROUP} --sku basic --admin-enabled true

# Cluster
az aks create -n ${CLUSTER_NAME} -g ${RESOURCE_GROUP} --attach-acr ${ACR_NAME}  --generate-ssh-keys```

# Login to Registry
az acr login --name ${ACR_NAME}
```

- Obtain kubernetes context and credentials for AZURE AKS
```
# Obtain Kubernetes credentials
az aks get-credentials --resource-group=${RESOURCE_GROUP} --name=${CLUSTER_NAME}

# Now you have set up the connection to multiple Kubernetes clusters, you need to switch between Kubernetes clusters
kubectl config get-contexts  # display list of contexts (i.e., clusters)

# Obtain correct context
kubectl config use-context GCP_OR_AZURE_CONTEXT  # set the default context (i.e, set the default cluster you will work on)
```

## Create the Ingress Resource
After you have changed the context to Azure Kubernetes clusters, create an ingress controller by running the following code:

- Create an NGINX ingress controller
```bash
helm install my-nginx bitnami/nginx-ingress-controller --version v9.3.24
```

- Create an Ingress resource
```
# Navigate to ``/Ingress_Azure`
cd Ingress_Azure

# Create resource
kubectl create -f ingress.yaml

# Check the state of the Ingress you just added with
kubectl get ingress
```

## Use Helm to deploy the Profile service to the AZURE cluster
- Set the values of the environment variables
```bash
export mysqlRootPassword=<REPLACE WITH ROOT PASSWORD>
export mysqlUser=<REPLACE WITH USERNAME>
export mysqlPassword=<REPLACE WITH USER PASSWORD>
```

- Install the MySQL backend
```bash
helm install mysql-profile --set auth.rootPassword=${mysqlRootPassword},auth.username=${mysqlUser},auth.password=${mysqlPassword},auth.database=test bitnami/mysql --set image.debug=true \
--set primary.persistence.enabled=false,secondary.persistence.enabled=false \
--set primary.readinessProbe.enabled=false,primary.livenessProbe.enabled=false \
--set secondary.readinessProbe.enabled=false,secondary.livenessProbe.enabled=false
```

- Install the Profile service
```bash
# Install profile service
helm install profile profile-service/src/main/helm/profile/

# Validate the helm installation
helm list
```

## Use Helm to deploy the Chat service to the AZURE cluster
- Set the values of the environment variables
```bash
export mysqlRootPassword=<REPLACE WITH ROOT PASSWORD>
export mysqlUser=<REPLACE WITH USERNAME>
export mysqlPassword=<REPLACE WITH USER PASSWORD>
```

- Install the MySQL backend
```bash
helm install chat --set auth.rootPassword=${mysqlRootPassword},auth.username=${mysqlUser},auth.password=${mysqlPassword},auth.database=test bitnami/mysql --set image.debug=true \
--set primary.persistence.enabled=false,secondary.persistence.enabled=false \
--set primary.readinessProbe.enabled=false,primary.livenessProbe.enabled=false \
--set secondary.readinessProbe.enabled=false,secondary.livenessProbe.enabled=false
```

- Install the Chat service
```bash
# Install group-chat service
helm install chat group-chat-service/src/main/helm/chat/

# Validate the helm installation
helm list
```

## Use Helm to deploy the Login service to the AZURE cluster
- Set the values of the environment variables
```bash
export mysqlRootPassword=<REPLACE WITH ROOT PASSWORD>
export mysqlUser=<REPLACE WITH USERNAME>
export mysqlPassword=<REPLACE WITH USER PASSWORD>
```

- Install the MySQL backend
```bash
helm install login --set auth.rootPassword=${mysqlRootPassword},auth.username=${mysqlUser},auth.password=${mysqlPassword},auth.database=test bitnami/mysql --set image.debug=true \
--set primary.persistence.enabled=false,secondary.persistence.enabled=false \
--set primary.readinessProbe.enabled=false,primary.livenessProbe.enabled=false \
--set secondary.readinessProbe.enabled=false,secondary.livenessProbe.enabled=false
```

- Install the login service
```bash
# Install login service
helm install login login-service/src/main/helm/login/

# Validate the helm installation
helm list
```
