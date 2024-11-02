provider "google" {
  project = "my-project-279-436907"
  region  = "us-central1"
}

resource "google_compute_network" "vpc-network" {
  name = "my-vpc-network"
  auto_create_subnetworks = true
}

resource "google_compute_instance_template" "nginx-template" {
  name         = "nginx-template"
  machine_type = "e2-medium"

  metadata_startup_script = file("startup.sh") # Ensure this file is present in the same directory

  disk {
    source_image = "debian-cloud/debian-11"
  }

  network_interface {
    network = google_compute_network.vpc-network.name
    access_config {
      // Ephemeral public IP
    }
  }
}

resource "google_compute_instance_group_manager" "nginx-group" {
  name               = "nginx-group"
  version {
    instance_template = google_compute_instance_template.nginx-template.id
  }
  target_size       = 2
  zone              = "us-central1-f"
}

resource "google_compute_forwarding_rule" "nginx-lb" {
  name        = "nginx-lb"
  region      = "us-central1"
  ip_address  = google_compute_address.nginx-ip.address
  port_range  = "80"
  target      = google_compute_target_pool.nginx-pool.self_link
}

resource "google_compute_target_pool" "nginx-pool" {
  name    = "nginx-pool"
  region  = "us-central1"
  health_checks = [google_compute_http_health_check.nginx-health-check.id]
}

resource "google_compute_http_health_check" "nginx-health-check" {
  name               = "nginx-health-check"
  request_path       = "/"
  check_interval_sec = 10
  timeout_sec        = 5
  healthy_threshold  = 2
  unhealthy_threshold = 2
}

resource "google_compute_firewall" "allow-http" {
  name    = "allow-http"
  network = google_compute_network.vpc-network.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
}
