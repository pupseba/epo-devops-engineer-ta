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
    "startup-script" = <<-EOF
      #!/bin/bash

      HOSTNAME=$(hostname)

      # Executes always

      ## Prepares system
      apt-get update -y
      apt install apt-transport-https -y

      ## Installs kubernetes packages
      curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
      echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
      apt update
      apt install kubelet kubeadm kubectl -y
      apt-mark hold kubelet kubeadm kubectl
      systemctl enable --now kubelet

      ## Installs containerd
      modprobe overlay
      modprobe br_netfilter

      cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes.conf
      net.bridge.bridge-nf-call-iptables = 1
      net.ipv4.ip_forward = 1
      net.bridge.bridge-nf-call-ip6tables = 1
      EOF

      sysctl --system
      tee /etc/modules-load.d/containerd.conf <<EOF
      overlay
      br_netfilter
      EOF

      sysctl --system

      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
      add-apt-repository --yes "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
      apt update
      apt install containerd.io -y
      containerd config default>/etc/containerd/config.toml
      systemctl restart containerd ; systemctl enable containerd
    EOF
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
