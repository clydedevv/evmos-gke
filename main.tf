provider "google" {
  credentials = file("/Users/clydecarver/evmos-gke-5f49a1378ef4.json")
  project     = "evmos-gke"
  region      = "europe-west1-d"
}

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

