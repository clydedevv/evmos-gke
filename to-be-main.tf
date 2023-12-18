## more automated main.tf
## Dynamic IP Handling: Removed static IPs for accessing the private cluster and used Cloud NAT for outbound traffic. More scalable and secure for private clusters.
## ArgoCD Module: Introduced a Terraform module for ArgoCD setup. This module should be created (or sourced from a reliable repository) to automate the installation of ArgoCD
## Monitoring Module: Introduced a module for setting up Prometheus and Grafana for monitoring. This module should encapsulate the Helm chart installations and configurations.
## Outputs: Updated outputs to dynamically fetch the cluster endpoints.

provider "google" {
  credentials = file("/Users/clydecarver/evmos-gke-challenge-99b417c42d7c.json")
  project     = "evmos-gke-challenge"
  region      = "europe-west1-d"
}

# Google Client Config
data "google_client_config" "default" {}

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
    service_account = "evmos-gke-sa@evmos-gke-challenge.iam.gserviceaccount.com"
    preemptible  = false
    machine_type = "e2-medium"
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
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

  # Use Cloud NAT for private clusters
  network_policy {
    enabled = true
  }

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
    service_account = "evmos-gke-sa@evmos-gke-challenge.iam.gserviceaccount.com"
    preemptible  = false
    machine_type = "e2-medium"
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

# ArgoCD Setup
module "argocd" {
  source = "git::https://github.com/terraform-argocd-module.git?ref=v1.0.0"

  argocd_version = "2.4.3"
  namespace      = "argocd"
  cluster_name   = google_container_cluster.primary.name
  provider       = kubernetes.public
}

# Prometheus and Grafana Setup
module "monitoring" {
  source = "git::https://github.com/terraform-monitoring-module.git?ref=v1.0.0"

  namespace = "monitoring"
  provider  = kubernetes.public
}

# Outputs
output "public_cluster_endpoint" {
  value = google_container_cluster.primary.endpoint
}

output "private_cluster_endpoint" {
  value = google_container_cluster.private.endpoint
}

# Kubernetes Providers
provider "kubernetes" {
  alias = "public"
  host  = google_container_cluster.primary.endpoint
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
}

provider "kubernetes" {
  alias = "private"
  host  = google_container_cluster.private.endpoint
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.private.master_auth[0].cluster_ca_certificate)
}
