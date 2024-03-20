# Microservices Orchestration on the Cloud

This guide provides step-by-step instructions to deploy the application from the [k8s-mastery](https://github.com/rinormaloku/k8s-mastery) repository on Google Kubernetes Engine (GKE).

#### URLs for the Docker Hub images that were used
- [sa-frontend-cloud: Front-end](https://hub.docker.com/r/okemawo1/sa-frontend-cloud) 
- [sa-webapp-cloud: Java back-end](https://hub.docker.com/r/okemawo1/sa-webapp-cloud)
- [sa-logic-cloud: Python back-end](https://hub.docker.com/r/okemawo1/sa-logic-cloud)

#### URLs for the video recordings
- [The application functionality demo on the cloud](https://drive.google.com/file/d/1HuzNS0RCTWZ8e8wyRsG4ntgedPzni69w/view?usp=sharing)
- [Code walkthrough for your code changes](https://drive.google.com/file/d/1TBoXN09Vl85EioJaVPjRcoaFDqC3j1cu/view?usp=sharing)

<br>
<br>

<p align="center">
  <img src="https://github.com/Cloud-Infrastructure-Fall-2023/hw-3-microservice-orchestration-okemawo/assets/65502643/94ec9ea9-a67b-4de3-a15e-a853f7fb9a1f" alt="Deployment Diagram">
</p>
<br>

## Prerequisites

- [Google Cloud Platform (GCP) account](https://console.cloud.google.com/)
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) installed
- `kubectl` (Kubernetes command-line tool) installed
- [Docker](https://www.docker.com/get-started) installed
- [nodeJs](https://nodejs.org/en) installed
- [npm](https://www.npmjs.com/) installed
- [maven](https://maven.apache.org/what-is-maven.html) installed
- [jdk](https://www.oracle.com/java/technologies/downloads/) installed


### Clone the Repository

```bash
git clone https://github.com/rinormaloku/k8s-mastery.git
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

### Configure and Build Docker Image for Java Back-end Mircoservice
- Change directory to k8s-mastery/sa-webapp/
```bash
cd k8s-mastery/sa-webapp/
```

- Intall packages for the application that generates the .jar executable in /target directory
```bash
mvn install
```

- Build the docker image for the "sa-webap" microservice 
```bash
docker build -f Dockerfile -t "docker user id"/sa-webapp-cloud .
```

- Push the docker image to docker hub
```bash
docker push "docker user id"/sa-webapp-cloud
```
<br>

### Configure and Build Docker Image for Python Back-end logic Mircoservice
- Change directory to k8s-mastery/sa-logic/
```bash
cd k8s-mastery/sa-logic/
```

- Add the following line as part of the arguments for the RUN command in the Dockerfile 
```text
pip3 install --upgrade flask
```

- Build the docker image for the "sa-logic" microservice 
```bash
docker build -f Dockerfile -t "docker user id"/sa-logic-cloud .
```

- Push the docker image to docker hub
```bash
docker push "docker user id"/sa-logic-cloud
```

<br>

### Configure and Build Docker Image for Front-End Mircoservice
- We first need to deploy the kubernetes service.yaml for the java back-end microservice, because the load balancer ip address gotten from deploying the service.yaml file to GKE is essential in the build process for the front-end application. The code that needs to be refactored can be seen in the screenshot below. Change directory to k8s-mastery/sa-frontend/src and inspect the "App.js" file to see the line that needs to be refactored to include the external ip for the back-end service.
```bash
cd k8s-mastery/sa-frontend/src
cat App.js
```
<p align="center">
  <img src="https://github.com/Cloud-Infrastructure-Fall-2023/hw-3-microservice-orchestration-okemawo/assets/65502643/61acb41f-5204-46a4-a24a-4138ca981b6e" alt="code snipped">
</p>

<br>

### Create GKE Cluster (Cloud shell)
- Open google cloud shell
[Google Cloud Platform (GCP)](https://console.cloud.google.com/)

- Set project 
```bash
gcloud config set project "project id"
```

- Set default zone and region
```bash
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a
```

- Enable GKE API
```bash
gcloud services enable container.googleapis.com
```

- Create GKE Cluster using the following command and replace "CLUSTER_NAME" and "NODE_COUNT" with the desired name and number of nodes respectively
```bash
gcloud container clusters create "CLUSTER_NAME" --num-nodes="NODE_COUNT"
```

- Wait for the cluster to be provisioned and then check with the following commmand (This will take a while)
```bash
gcloud container clusters list
```

- Configure "kubectl" to execute commands in the cluster
```bash
gcloud container clusters get-credentials "CLUSTER_NAME"
```

<br>

### Copy deployment and service files to cloud shell editor
- To make things easier for you when to create the deployment and services, you can copy the deployment and service files from /k8s-mastery/resource-manifests into the cloud shell editor where you can edit the files and execute commands in the terminal to carry out the deployments and services. Alternatively, you could create a bucket and access them there via their url.
  
- Change directory to the /k8s-mastery/resource-manifests where we can find some deployment and service files
```bash
cd /k8s-mastery/resource-manifests
```

### Create a deployment to provision the java back-end microservice pods 
- Open the "sa-web-app-deployment.yaml" and change the env.value for the template to "http://sa-logic:5000" as seen in the screenshot below
<p align="center">
  <img src="https://github.com/Cloud-Infrastructure-Fall-2023/hw-3-microservice-orchestration-okemawo/assets/65502643/f6fccff0-9515-4a2c-97d4-8be3c932966b" alt="code snipped">
</p>

<p align="center">
  <img src="https://github.com/Cloud-Infrastructure-Fall-2023/hw-3-microservice-orchestration-okemawo/assets/65502643/6d66d2d3-cedf-4cbd-83e2-001e60b2d087" alt="code snipped">
</p>

- Change the image for the deployment to be the url for the publicly accessible image pushed to docker hub in the previous steps
<p align="center">
  <img src="https://github.com/Cloud-Infrastructure-Fall-2023/hw-3-microservice-orchestration-okemawo/assets/65502643/1ff6b33c-8d8e-4ce8-b773-2ee44b74f2d8" alt="code snipped">
</p>

<p align="center">
  <img src="https://github.com/Cloud-Infrastructure-Fall-2023/hw-3-microservice-orchestration-okemawo/assets/65502643/c29f1bcf-1780-4327-8b79-49c55b791c8b" alt="code snipped">
</p>

- Create the deployment by executing this command
```bash
kubectl apply -f sa-web-app-deployment.yaml
kubectl get pods
```

<br>

### Create a deployment to provision the python back-end microservice pods 
- Open the "sa-logic-deployment.yaml" and change the container.image field to the docker hub image you pushed in the previous steps
<p align="center">
  <img src="https://github.com/Cloud-Infrastructure-Fall-2023/hw-3-microservice-orchestration-okemawo/assets/65502643/c18ab526-cb50-4676-85da-a6a78933029a" alt="code snipped">
</p>

<p align="center">
  <img src="https://github.com/Cloud-Infrastructure-Fall-2023/hw-3-microservice-orchestration-okemawo/assets/65502643/a7c12c0e-a589-42a7-80d1-b55ff2ef79a5" alt="code snipped">
</p>

- Create the deployment by executing this command
```bash
kubectl apply -f sa-logic-deployment.yaml
kubectl get pods
```

<br>

### Create a Kubernetes Service for the Java Back-End Microservice
- Edit the port and target port field in the "service-sa-web-app-lb.yaml" file as seen in the images below
<p align="center">
  <img src="https://github.com/Cloud-Infrastructure-Fall-2023/hw-3-microservice-orchestration-okemawo/assets/65502643/253d3726-7b01-49eb-9701-4c9303d951c6" alt="code snipped">
</p>

<p align="center">
  <img src="https://github.com/Cloud-Infrastructure-Fall-2023/hw-3-microservice-orchestration-okemawo/assets/65502643/397ed2f2-f5a0-451e-a2b5-16ca20fb3a2c" alt="code snipped">
</p>

- Create the service by executing this command
```bash
kubectl apply -f service-sa-web-app-lb.yaml
kubectl get service
```

- GKE will provide us with an external IP address we will need to embed in our build for the front-end image, as mentioned in the previous steps. Execute the following command to obtain the external IP address. We got this IP because we configured the service.type field withing the service.yaml file to be a load balancer
```bash
kubectl get service
```

<br>

### Create a Kubernetes Service for the pyhton Back-End Microservice
- Edit the port field in the "service-sa-logic.yaml" file as seen in the images below
<p align="center">
  <img src="https://github.com/Cloud-Infrastructure-Fall-2023/hw-3-microservice-orchestration-okemawo/assets/65502643/6a6f76e2-c5dd-444e-8e3a-e12c0f04d279" alt="code snipped">
</p>

<p align="center">
  <img src="https://github.com/Cloud-Infrastructure-Fall-2023/hw-3-microservice-orchestration-okemawo/assets/65502643/01a49041-8247-41e4-a441-2f6067ceb1b7" alt="code snipped">
</p>

- Create the service by executing this command
```bash
kubectl apply -f service-sa-logic.yaml
kubectl get service
```

<br>

### Create a deployment to provision the Front-End microservice pods 
- Remember we havent built the front-end image because we needed the load balancer IP from the web-app GKE service. Now we will obtain the external IP from GKE, and embed it into the front-end application, build the image, push it to docker hub, then finally create the deployment and the service.

- change directory to /k8s-mastery/sa-frontend/src
```bash
cd /k8s-mastery/sa-frontend/src
```

- Open "App.js" and edit the code with the ip address obtained from the java web-app external ip for the the service
<p align="center">
  <img src="https://github.com/Cloud-Infrastructure-Fall-2023/hw-3-microservice-orchestration-okemawo/assets/65502643/dc2a43d8-e2cf-4f01-ab23-5e91170d3796" alt="code snipped">
</p>

- Change directory to /k8s-mastery/sa-frontend
```bash
cd /k8s-mastery/sa-frontend
```

- Build the project to create the static files in the /build folder fro a production ready site
```bash
npm run build
```

- Build the docker image and push to docker hub
```bash
docker build -f Dockerfile -t "docker user id"/sa-frontend-cloud .
docker push "docker user id"/sa-frontend-cloud
```


- Open the "sa-frontend-deployment.yaml" and change the container.image field to the docker hub image you pushed in the previous steps
<p align="center">
  <img src="https://github.com/Cloud-Infrastructure-Fall-2023/hw-3-microservice-orchestration-okemawo/assets/65502643/324093e1-fe7a-4591-ac27-1ede3ac71a0a" alt="code snipped">
</p>

- Create the deployment by executing this command
```bash
kubectl apply -f sa-frontend-deployment.yaml
kubectl get pods
```

<br>

### Create a Kubernetes Service for the Front-End Microservice
- Create the service by executing this command
```bash
kubectl apply -f service-sa-frontend-lb.yaml
```

- Obtain the service external ip by executing this command
```bash
kubectl get service
```

- Launch the application by putting the ip address in the browser
<p align="center">
  <img src="https://github.com/Cloud-Infrastructure-Fall-2023/hw-3-microservice-orchestration-okemawo/assets/65502643/20fdce10-b478-4463-882e-ce909c4afd4a" alt="code snipped">
</p>

<br>
<br>
<br>

# ALL DONE!!!
