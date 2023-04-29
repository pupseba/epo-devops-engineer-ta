resource "google_compute_firewall" "rules" {
  name        = "allow-6443"
  network     = "default"
  direction   = "INGRESS"
  description = "Creates fw rule for allowing traffic to masters in port 6443"

  allow {
    protocol = "tcp"
    ports    = ["6443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["master"]
}