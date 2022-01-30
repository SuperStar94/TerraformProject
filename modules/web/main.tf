terraform {
  required_providers {
     scaleway = {
        source = "scaleway/scaleway"
   }
}
  required_version = ">= 0.13"
}

        provider "scaleway" {
        zone = "fr-par-1"
        region = "fr-par"
}


####################################### Security group for Web/App

resource "scaleway_instance_security_group" "app" {
  inbound_default_policy = "drop"
  name = "SG-RSAF-APP"
  description = "Security group pour le serveur web/app" 

  inbound_rule {
    action = "accept"
    port   = 80
    protocol = "ANY"
    ip_range = "0.0.0.0/0"
  }
  
  inbound_rule {
    action     = "accept"
    protocol   = "ANY"
    ip_range = "192.168.2.0/24"
  }
}

######################## Create PN & Public gateway for Web/App

resource "scaleway_vpc_private_network" "pn_app" {
  name = "app_private_network"
}

resource "scaleway_vpc_public_gateway_ip" "gw_app" {

}

resource "scaleway_vpc_public_gateway_dhcp" "dhcp_app" {
  subnet = "192.168.1.0/24"
}

resource "scaleway_vpc_public_gateway" "pg_app" {
  name = "public_gateway_app"
  type = "VPC-GW-M"
  ip_id = scaleway_vpc_public_gateway_ip.gw_app.id
}

resource "scaleway_vpc_gateway_network" "app" {
  gateway_id = scaleway_vpc_public_gateway.pg_app.id
  private_network_id = scaleway_vpc_private_network.pn_app.id
  dhcp_id = scaleway_vpc_public_gateway_dhcp.dhcp_app.id
}


############## Create instance server

resource "scaleway_instance_ip" "public_ip" {

}

resource "scaleway_instance_server" "web" {
        type = "GP1-S"
        name = "NTE-RSAF-APP"
        image = "ubuntu_focal"
        tags = ["web", "application"]
        ip_id = scaleway_instance_ip.public_ip.id
	security_group_id = scaleway_instance_security_group.app.id
	private_network {
               pn_id = scaleway_vpc_private_network.pn_app.id
  }

connection {
    type        = "ssh"
    user        = "root"
    host        = "${self.public_ip}"
    private_key = file("/root/.ssh/id_ed25519")
    agent       = false
  }

provisioner "file" {
    source      = "${path.module}/provisioner.sh"
    destination = "/tmp/provisioner.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/provisioner.sh",
      "/tmp/provisioner.sh",
    ]
  }

}

##################################### Load Balancer

resource "scaleway_lb_ip" "ip" {
}

resource "scaleway_lb" "lb01" {
  ip_id  = scaleway_lb_ip.ip.id
  name = "NTE-RSAF-LB"
  zone = "fr-par-1"
  type   = "LB-S"
  release_ip = false
  private_network {
        private_network_id = scaleway_vpc_private_network.pn_app.id
        static_config = ["192.168.1.10", "192.168.1.20"]
    }
}

resource "scaleway_lb_backend" "backend01" {
  lb_id            = scaleway_lb.lb01.id
  name             = "RSAF-BACKEND01"
  forward_protocol = "http"
  forward_port     = "80"
  server_ips = ["${scaleway_instance_server.web.private_ip}"]
}


resource "scaleway_lb_frontend" "frontend01" {
  lb_id        = scaleway_lb.lb01.id
  backend_id   = scaleway_lb_backend.backend01.id
  name         = "RSAF-FRONTEND01"
  inbound_port = "80"
}

