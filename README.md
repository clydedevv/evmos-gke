# Step 1: GKE Cluster Creation Using Terraform

This section documents the process of creating a Google Kubernetes Engine (GKE) cluster using Terraform. 

## Overview

I utilized Terraform, an Infrastructure as Code (IaC) tool, to automate the deployment of a GKE cluster. This approach ensures repeatability, consistency, and documentation of our infrastructure setup.

## Steps

1. **Terraform Initialization:**
   - Initialized Terraform in the project directory to prepare the environment and download necessary providers.

2. **Service Account Creation:**
   - Created a service account in Google Cloud Platform (GCP) with necessary permissions to manage GKE resources.

3. **Terraform Configuration:**
   - Wrote Terraform configuration (`main.tf`) defining:
     - Google provider with GCP credentials.
     - GKE cluster resource with desired specifications (region, node count, machine type).

4. **Cluster Deployment:**
   - Applied the Terraform configuration to deploy the GKE cluster.
   - Verified the cluster creation in GCP console.

## Cluster Specifications

- **Cluster Name:** evmos-gke-cluster
- **Location:** europe-west1-d
- **Node Count:** 2
- **Machine Type:** e2-medium (per node)
- **Memory:** 8 GB (per node)

## Key Terraform Commands

- `terraform init`: Initialize Terraform workspace.
- `terraform plan`: Review changes before applying.
- `terraform apply`: Deploy the configuration.

## Next Steps

With the GKE cluster now in place, the next phase is to automate the deployment of ArgoCD, a tool for continuous delivery, to manage applications within the Kubernetes cluster.

# Step 2: ArgoCD Installation Using Helm

This section outlines the process of installing ArgoCD on the Google Kubernetes Engine (GKE) cluster using Helm, which is a package manager for Kubernetes.

## Overview

ArgoCD is a continuous delivery tool for Kubernetes that automates the deployment of applications from Git repositories to Kubernetes clusters. It follows the GitOps methodology, making deployments easier and more transparent.

## Installation Steps

1. **Helm Installation:**
   - Ensured that Helm, the Kubernetes package manager, was installed on the local machine.

2. **Helm Repository Setup:**
   - Added the ArgoCD repository to Helm by running:
     ```bash
     helm repo add argo https://argoproj.github.io/argo-helm
     ```

3. **Deploy ArgoCD:**
   - Created a basic `values.yaml` file to configure the ArgoCD installation.
   - Installed ArgoCD onto the Kubernetes cluster using Helm with the command:
     ```bash
     helm install argocd argo/argo-cd -f values.yaml
     ```

## Accessing ArgoCD UI

- **Port Forwarding:**
  - To access the ArgoCD UI, set up port forwarding with the command:
    ```bash
    kubectl port-forward service/argocd-server -n default 8080:443
    ```
  - The ArgoCD UI can then be accessed at http://localhost:8080.

- **Admin Password Retrieval:**
  - The initial admin password for ArgoCD can be retrieved with:
    ```bash
    kubectl -n default get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
    ```

- **Deleting the Initial Secret:**
  - For security, it's recommended to delete the initial admin secret after logging in for the first time:
    ```bash
    kubectl -n default delete secret argocd-initial-admin-secret
    ```

## Next Steps

With ArgoCD successfully installed and configured, the next step involves setting up ArgoCD to manage applications across the Kubernetes cluster. This will include the deployment of our main application, `evmosd`, as well as configuring monitoring and other necessary services.

## Additional Notes

- The `values.yaml` file used for the Helm deployment can be customized further for more advanced configurations of ArgoCD.
- It is advisable to set up ingress for ArgoCD for easier and more secure access. This can be configured in the `values.yaml` file under the `server.ingress.enabled` section.
