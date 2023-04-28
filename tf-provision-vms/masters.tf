resource "google_compute_instance" "master" {
  count        = 1
  name         = format("master%02d", count.index + 1)
  machine_type = "e2-micro"
  zone         = "europe-west6-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
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
