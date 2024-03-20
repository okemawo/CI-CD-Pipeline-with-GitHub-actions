# A Multicloud CI/CD Pipeline with Github actions

This project employs a Continuous Integration/Continuous Deployment (CI/CD) pipeline using GitHub Actions. The pipeline is defined in the `.github/workflows/cicd.yml` file.

## Workflow Overview

The workflow is activated on push events to the `main` branch and can also be manually triggered from the Actions tab.

The workflow is composed of several jobs:

1. **check-changed-files**: This job checks for any modifications in the source code of specific microservices (`/src/chat`, `/src/login`, `/src/profile`) and outputs the results (true if any changes).

2. **build-push-image**: This job builds and pushes Docker images for the microservices that have undergone changes. The images are tagged with the commit SHA and pushed to both Google Cloud Registry (GCR) and Azure Container Registry (ACR).

3. **deploy**: This job deploys the updated microservices to both Google Cloud Platform (GCP) and Azure.

## Environment Variables

The workflow uses several environment variables, which are defined in the `env` section of the `.github/workflows/cicd.yml` file. These include:

- `GCP_CLUSTER_NAME`: The name of the GCP cluster.
- `GCP_PROJECT_ID`: The ID of the GCP project.
- `GCP_REGION`: The GCP region.
- `AZ_CONTAINER_REGISTRY`: The Azure Container Registry.
- `AZ_CLUSTER_NAME`: The name of the Azure cluster.
- `AZ_RESOURCE_GROUP`: The Azure resource group.
- `DOCKER_TAG`: The Docker tag, which is set to the commit SHA.

## Docker Image Building

Docker images are built for each microservice that has changed. The Dockerfiles are located in the `src/{microservice}/main/docker` directory of each microservice. The images are tagged with the commit SHA and pushed to both GCR and ACR.

## Deployment

The deployment is done using Helm charts. The deployment files are updated to use the Docker images that were just pushed. The updated microservices are then deployed to both GCP and Azure.

## Azure and GCP Authentication

The workflow uses the `google-github-actions/auth` action to authenticate to Google Cloud, and the `azure/login` action to authenticate to Azure. The credentials for these services are stored as GitHub secrets.

## Terraform Variables

Terraform variables are defined in the `terraform/variables.tf` file. These include the name of the Front Door instance, the resource group name in Azure, and the ingress external IPs in GCP and Azure.


# Running the Project

To run the project, you need to trigger the CI/CD pipeline. This is done by pushing a change to the `main` branch. Here's a step-by-step guide:

1. **Make a Change**: Modify the source code of any of the microservices (`/src/chat`, `/src/login`, `/src/profile`). This could be a new feature, a bug fix, or any other change.

2. **Commit the Change**: Use Git to commit the change. Make sure to write a clear and concise commit message that describes what the change does.

   ```bash
   git add .
   git commit -m "Your descriptive commit message"
   ```

3. **Push the Change**: Push the committed change to the `main` branch. This will trigger the CI/CD pipeline.

   ```bash
   git push origin main
   ```

Once the change is pushed, the CI/CD pipeline will automatically start. It will check for changes in the microservices, build and push Docker images for the changed microservices, and deploy the updated microservices to both Google Cloud Platform (GCP) and Azure.

You can monitor the progress of the pipeline in the Actions tab on GitHub. If the pipeline completes successfully, your changes are now live on both GCP and Azure.

Remember, you can also manually trigger the pipeline from the Actions tab if needed.
