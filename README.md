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

# Step 2: Automated ArgoCD Installation Using Terraform and Helm

## Overview

In this step, I automated the installation of ArgoCD on our Google Kubernetes Engine (GKE) cluster using Terraform in combination with Helm. ArgoCD is a Kubernetes-native continuous delivery tool that simplifies the deployment and management of applications.

## Automated Installation Process

1. **Terraform Configuration:**
   - Added Helm provider and a Helm release resource to our `main.tf` Terraform configuration.
   - Specified the ArgoCD Helm chart and its version, along with the custom `values.yaml` file for configuration.

2. **Applying Terraform Configuration:**
   - Ran `terraform apply` to automatically deploy ArgoCD onto the Kubernetes cluster.

## Accessing ArgoCD UI

- **Port Forwarding:**
  - To access the ArgoCD UI, you can set up port forwarding with:
    ```bash
    kubectl port-forward service/argocd-server -n default 8080:443
    ```
  - Access the UI at http://localhost:8080.

- **Admin Password Retrieval:**
  - Retrieve the initial admin password for ArgoCD with:
    ```bash
    kubectl -n default get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
    ```

- **Deleting the Initial Secret:**
  - It's recommended to delete the initial admin secret for security:
    ```bash
    kubectl -n default delete secret argocd-initial-admin-secret
    ```

## Customization and Configuration

- The `values.yaml` file used in the Helm chart can be customized for advanced configurations of ArgoCD.
- Configuring ingress in the `values.yaml` under `server.ingress.enabled` is advisable for easier and secure access.

## Next Steps

With ArgoCD now installed and operational, we'll focus on setting it up to manage applications across both the public and private GKE clusters.

# Step 3: Creation of a Private GKE Cluster

## Overview

This step involves creating a private Google Kubernetes Engine (GKE) cluster using Terraform. A private cluster enhances security by ensuring that the nodes are not exposed to the public internet.

## Terraform Configuration for Private Cluster

1. **Cluster and Node Pool Configuration:**
   - Defined a `google_container_cluster` resource for the private cluster in `main.tf`.
   - Configured `private_cluster_config` to make the cluster private.
   - Added a `google_container_node_pool` resource for the node pool associated with the private cluster.

2. **Security Settings:**
   - Used `master_authorized_networks_config` to allow specific IP ranges (the public cluster's IP) to access the private cluster's Kubernetes API server.

3. **Applying the Configuration:**
   - Ran `terraform apply` to create the private cluster with the specified configuration.

## Cluster Details

- **Cluster Name:** evmos-private-gke-cluster
- **Location:** europe-west1-d
- **Node Count:** 2
- **Machine Type:** e2-medium
- **Master Authorized Networks:** Enabled to allow access from the public cluster.

## Next Steps

With the private GKE cluster now in place, the next phase involves configuring ArgoCD to manage applications on both the public and private clusters.

# Step 4: Ensure ArgoCD can manage both clusters 
![image](https://github.com/clydedevv/evmos-gke/assets/80094928/c74cfd50-e82d-48f6-b6e9-f7536b3e9886)
ArgoCD is configured to run with the public cluster. Roadblocked on how to get it connected to the private cluster, I've followed up with Traiano and Amine and waiting for some guidance. 
I configured master_authorized_networks_config in the Terraform script to include the public cluster's external IP and your personal IP for the private cluster, ensuring controlled access.Tried to use argocd cluster add command to add the private cluster to ArgoCD. This step typically creates the necessary service accounts, roles, and role bindings in the target cluster. Encountered an issue with the command timing out, likely due to network connectivity problems between the public cluster (where ArgoCD is running) and the private cluster.

Reviewed and updated the network settings in the Terraform configuration to ensure the private cluster's API server is accessible from the public cluster.
Attempted various network configurations, including adding different IP addresses to the master_authorized_networks_config to improve connectivity.

Explored using an existing IAM role with sufficient access (evmos-gke-sa@evmos-gke-challenge.iam.gserviceaccount.com) for managing both clusters.
Attempted to create a Kubernetes secret with the service account token to manually add the private cluster to ArgoCD. However, faced issues with the token not being set correctly.

Explored manually registering the private cluster in ArgoCD by creating a secret with the kubeconfig of the private cluster. This approach bypasses the argocd cluster add command and directly injects the necessary configuration into ArgoCD. Still encountered issues, might be my Kubectl version?

