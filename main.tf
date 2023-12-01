provider "google" {
  credentials = file("/Users/clydecarver/evmos-gke-5f49a1378ef4.json")
  project     = "evmos-gke"
  region      = "europe-west1-d"
}

# Public GKE Cluster Configuration
resource "google_container_cluster" "primary" {
  name     = "evmos-gke-cluster"
  location = "europe-west1-d"

  remove_default_node_pool = true
  initial_node_count = 1

  master_auth {

    client_certificate_config {
      issue_client_certificate = false
    }
  }
}
# Public GKE Cluster Node Pool Configuration
resource "google_container_node_pool" "primary_nodes" {
  name       = "evmos-gke-nodes"
  location   = "europe-west1-d"
  cluster    = google_container_cluster.primary.name
  node_count = 2

  node_config {
    preemptible  = false
    machine_type = "e2-medium"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

# Private GKE Cluster Configuration
resource "google_container_cluster" "private" {
  name     = "evmos-private-gke-cluster"
  location = "europe-west1-d"

  remove_default_node_pool = true
  initial_node_count       = 1

  private_cluster_config {
    enable_private_nodes    = true
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

# Restrict access to the cluster master endpoint
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "35.190.210.212/32"  # Public cluster external IP
      display_name = "public-cluster-access"
    }
  }

# Secures the API server by disabling less secure authentication mechanisms
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }
}
# Private GKE Cluster Node Pool Configuration
resource "google_container_node_pool" "private_nodes" {
  name       = "evmos-private-gke-nodes"
  location   = "europe-west1-d"
  cluster    = google_container_cluster.private.name
  node_count = 2

  node_config {
    preemptible  = false
    machine_type = "e2-medium"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

# Automate ArgoCD installation 
# Add the Helm provider
provider "helm" {
  kubernetes {
    config_path = "~/.kube/config" # Path to your Kubernetes config file
  }
}

# Define the ArgoCD Helm release
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.51.5" # Specify the version you want to install

  values = [
    "${file("values.yaml")}"
  ]
}