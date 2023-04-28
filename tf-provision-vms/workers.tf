resource "google_compute_instance" "worker" {
  count        = 1
  name         = format("worker%02d", count.index + 1)
  machine_type = "e2-micro"
  zone         = "europe-west6-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size = "20"
    }
  }

  network_interface {
    network = google_compute_network.main.name
    subnetwork = google_compute_subnetwork.private.name
  }

  metadata = {
    "startup-script" = <<-EOF
      #!/bin/bash
      echo "Hello, World!" > index.html
    EOF
  }

  tags = ["worker","kubernetes"]
}