resource "google_compute_instance" "master" {
  count        = 1
  name         = format("master%02d", count.index + 1)
  machine_type = "e2-medium"
  zone         = "europe-west6-a"
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size = "20"
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }

  metadata = {
    ssh-keys = "core:${file("~/.ssh/core.pub")}"
    "startup-script" = <<-EOF
      #!/bin/bash
      echo "Hello, World!" > index.html
    EOF
  }

  tags = ["master","kubernetes"]
}
