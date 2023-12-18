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
      cidr_block   = "86.88.180.158/32"  # Personal IP
      display_name = "home-network-access"
    }
    cidr_blocks {
      cidr_block   = "104.199.13.13/32"  # ArgoCD IP
      display_name = "argocd-access"
    }
    cidr_blocks {
      cidr_block   = "34.38.196.80/32"  # Public cluster external IP
      display_name = "public-cluster-access"
    }
    cidr_blocks {
      cidr_block   = "34.38.135.207/32"  # Public cluster node 1 external IP
      display_name = "public-node-1-access"
    }
    cidr_blocks {
      cidr_block   = "35.233.116.195/32"  # Public cluster node 2 external IP
      display_name = "public-node-2-access"
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
    service_account = "evmos-gke-sa@evmos-gke-challenge.iam.gserviceaccount.com"
    preemptible  = false
    machine_type = "e2-medium"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

# Automate ArgoCD namespace installation 
resource "kubernetes_namespace" "argocd" {
  provider = kubernetes.public
  metadata {
    name = "argocd"
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

#testing endpoints
output "public_cluster_endpoint" {
  value = "https://${google_container_cluster.primary.endpoint}"
}

output "private_cluster_endpoint" {
  value = "https://${google_container_cluster.private.endpoint}"
}

#set kubernetes providers
provider "kubernetes" {
  alias                  = "public"

  host = "https://${google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
}

#set kubernetes providers
provider "kubernetes" {
  alias                  = "private"

  host = "https://${google_container_cluster.private.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.private.master_auth[0].cluster_ca_certificate)
}


##MONITORING
resource "kubernetes_namespace" "monitoring" {
  provider = kubernetes.public
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  namespace  = "monitoring"
  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }
}

resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  namespace  = "monitoring"
  set {
    name  = "service.type"
    value = "LoadBalancer"
  }
}
