resource "google_compute_instance" "worker" {
  count        = 1
  name         = format("worker%02d", count.index + 1)
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
    "startup-script" = file("scripts/startup.sh")
  }

  provisioner "file" {
    source      = "/home/pup_seba/.ssh/core"
    destination = "/tmp/core"
    connection {
      type = "ssh"
      user = "core"
      private_key = file("/home/pup_seba/.ssh/core")
      agent = "false"
      host = google_compute_instance.worker[count.index].network_interface[0].access_config[0].nat_ip
    }
  }

  tags = ["worker","kubernetes"]
}
