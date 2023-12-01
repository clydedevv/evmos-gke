# Step 1: GKE Cluster Creation Using Terraform

This section documents the process of creating a Google Kubernetes Engine (GKE) cluster using Terraform. 

## Overview

I utilized Terraform, an Infrastructure as Code (IaC) tool, to automate the deployment of a GKE cluster. This approach ensures repeatability, consistency, and documentation of our infrastructure setup.

## Steps

1. **Terraform Initialization:**
   - Initialized Terraform in our project directory to prepare the environment and download necessary providers.

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
