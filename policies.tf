provider "consul" {
  address        = "${aws_instance.consul.*.public_ip[0]}:8501"
  scheme         = "https"
  datacenter     = "dc1"
  token          = var.consul_initial_management_token
  insecure_https = true
}

resource "consul_admin_partition" "nomad" {
  name        = "nomad"
  description = "Partition for Nomad"
}

resource "consul_acl_policy" "consul_client" {
  name      = "consul-client"
  partition = "default"

  rules = <<-RULE
    partition "nomad" {
      node_prefix "" {
        policy = "write"
      }
    }
    RULE
}

resource "consul_acl_token" "consul_client" {
  description = "Consul Client Policy"
  policies    = ["${consul_acl_policy.consul_client.name}"]
  local       = true
  partition   = "default"
}

resource "consul_acl_policy" "nomad_server" {
  name      = "nomad-server"
  partition = consul_admin_partition.nomad.name

  rules = <<-RULE
    agent_prefix "" {
        policy = "read"
    }
    node_prefix "" {
        policy = "read"
    }
    service_prefix "" {
        policy = "write"
    }
    acl = "write"
    RULE
}

resource "consul_acl_token" "nomad_server" {
  description = "Nomad Server Policy"
  policies    = ["${consul_acl_policy.nomad_server.name}"]
  local       = true
  partition   = consul_admin_partition.nomad.name
}

resource "consul_acl_policy" "nomad_client" {
  name      = "nomad-client"
  partition = consul_admin_partition.nomad.name

  rules = <<-RULE
    agent_prefix "" {
        policy = "read"
    }
    node_prefix "" {
        policy = "read"
    }
    service_prefix "" {
        policy = "write"
    }
    # uncomment if using Consul KV with Consul Template
    # key_prefix "" {
    #   policy = read
    # }
    RULE
}

resource "consul_acl_token" "nomad_client" {
  description = "Nomad Client Policy"
  policies    = ["${consul_acl_policy.nomad_client.name}"]
  local       = true
  partition   = consul_admin_partition.nomad.name
}

resource "consul_config_entry" "count-api" {
  name      = "count-api"
  partition = consul_admin_partition.nomad.name
  kind      = "service-intentions"

  config_json = jsonencode({
    Sources = [{
      Action     = "allow"
      Name       = "count-dashboard"
      Precedence = 9
      Type       = "consul"
    }]
  })
}

data "consul_acl_token_secret_id" "consul_client" {
  accessor_id = consul_acl_token.consul_client.id
}

# data "consul_acl_token_secret_id" "nomad_server" {
#   accessor_id = consul_acl_token.nomad_server.id
# }

# data "consul_acl_token_secret_id" "nomad_client" {
#   accessor_id = consul_acl_token.nomad_client.id
#   partition   = consul_admin_partition.nomad.name
# }

locals {
  consul_acl_token_secret_id = {
    nomad_server = "341dacc7-fb95-b30e-9c64-9166cd19212f"
    nomad_client = "ca7fc841-03f1-b3fc-1aa4-0e22de6936e1"
  }
}