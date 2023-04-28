resource "google_compute_instance" "worker" {
  count        = 3
  name         = "format("worker%02d", count.index + 1)"
  machine_type = "e2-micro"
  zone         = "europe-west6-a"

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-101-lts"
      size = "20"
    }
  }

  network_interface {
    network = "default"
  }

  metadata = {
    "startup-script" = <<-EOF
      #!/bin/bash
      echo "Hello, World!" > index.html
    EOF
  }

  tags = ["worker","kubernetes"]
}