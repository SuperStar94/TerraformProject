terraform {
  required_providers {
    scaleway = {
      source = "scaleway/scaleway"
    }
  }
  required_version = ">= 0.13"
}

provider "scaleway" {
  zone   = "fr-par-1"
  region = "fr-par"
}

# with private network and dhcp configuration
resource "scaleway_vpc_private_network" "pn_data" {
  name = "database_private_network"
}

resource "scaleway_vpc_public_gateway_dhcp" "dhcp_data" {
  subnet = "192.168.2.0/24"
}

resource "scaleway_vpc_public_gateway_ip" "pb_data" {
}

resource "scaleway_vpc_public_gateway" "gw_data" {
  name  = "public_gateway_data"
  type  = "VPC-GW-S"
  ip_id = scaleway_vpc_public_gateway_ip.pb_data.id
}



resource "scaleway_vpc_gateway_network" "data" {
  gateway_id         = scaleway_vpc_public_gateway.gw_data.id
  private_network_id = scaleway_vpc_private_network.pn_data.id
  dhcp_id            = scaleway_vpc_public_gateway_dhcp.dhcp_data.id
  cleanup_dhcp       = true
  enable_masquerade  = true
  depends_on         = [scaleway_vpc_public_gateway_ip.pb_data, scaleway_vpc_private_network.pn_data]
}


resource "scaleway_vpc_public_gateway_pat_rule" "pat_data" {
  gateway_id   = scaleway_vpc_public_gateway.gw_data.id
  private_ip   = scaleway_vpc_public_gateway_dhcp.dhcp_data.address
  private_port = scaleway_rdb_instance.db01.private_network.0.port
  public_port  = 42
  protocol     = "both"
  depends_on   = [scaleway_vpc_gateway_network.data, scaleway_vpc_private_network.pn_data]
}


resource "scaleway_rdb_acl" "acl01" {
  instance_id = scaleway_rdb_instance.db01.id
  acl_rules {
    ip = "192.168.1.0/24"
    description = "Autorisation serveur web/app"
  }
}


resource "scaleway_rdb_instance" "db01" {
  name              = "NTE-RSAF-RDB"
  node_type         = "db-dev-s"
  engine            = "MySQL-8"
  is_ha_cluster     = false
  disable_backup    = true
  user_name         = "django"
  password          = "$aladeOgnon44"
  region            = "fr-par"
  tags              = ["database_instance", "rdb_pn_data"]
  volume_type       = "bssd"
  volume_size_in_gb = 50
  private_network {
    ip_net = "192.168.2.30/24"
    pn_id  = scaleway_vpc_private_network.pn_data.id
  }
}
