resource "google_compute_instance" "master01" {
  name         = "master01"
  machine_type = "e2-micro"
  zone         = "europe-west6-a"

  boot_disk {
    initialize_params {
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

  tags = ["master","kubernetes"]
}
