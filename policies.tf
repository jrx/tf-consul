provider "consul" {
  address        = "${aws_instance.consul.*.public_ip[0]}:8501"
  scheme         = "https"
  datacenter     = "dc1"
  token          = var.consul_initial_management_token
  insecure_https = true
}

resource "consul_acl_policy" "consul_client" {
  name  = "consul-client"
  rules = <<-RULE
    node_prefix "" {
        policy = "write"
    }
    RULE
}

resource "consul_acl_token" "consul_client" {
  description = "Consul Client Policy"
  policies    = ["${consul_acl_policy.consul_client.name}"]
  local       = true
}

resource "consul_acl_policy" "consul_replication" {
  name  = "consul-replication"
  rules = <<-RULE
  operator = "write"
  agent_prefix "" {
    policy = "read"
  }
  node_prefix "" {
    policy = "write"
  }
  namespace_prefix "" {
    acl = "write"
    service_prefix "" {
      policy = "read"
      intentions = "read"
    }
  }
    RULE
}

resource "consul_acl_token" "consul_replication" {
  description = "Consul Replication Policy"
  policies    = ["${consul_acl_policy.consul_replication.name}"]
  local       = false
}

resource "consul_acl_policy" "consul_mesh_gateway" {
  name  = "consul-mesh-gateway"
  rules = <<-RULE
    namespace_prefix "" {
      service_prefix "gateway" {
        policy = "write"
      }
      service_prefix "" {
        policy = "read"
      }
    }
    node_prefix "" {
      policy = "read"
    }
    agent_prefix "" {
      policy = "read"
    }
    RULE
}

resource "consul_acl_token" "consul_mesh_gateway" {
  description = "Consul Mesh Gateway Policy"
  policies    = ["${consul_acl_policy.consul_mesh_gateway.name}"]
  local       = true
}

resource "consul_acl_policy" "nomad_server" {
  name  = "nomad-server"
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
}

resource "consul_acl_policy" "nomad_client" {
  name  = "nomad-client"
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
}

resource "consul_config_entry" "proxy_defaults" {
  kind = "proxy-defaults"
  name = "global"

  config_json = jsonencode({
    MeshGateway = {
      Mode = "local"
    }
  })
}

resource "consul_config_entry" "count-api" {
  name = "count-api"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [{
      Action     = "allow"
      Name       = "count-dashboard"
      Type       = "consul"
    },{
      Action     = "allow"
      Name       = "count-dashboard-dc2"
      Type       = "consul"
    }]
  })
}

data "consul_acl_token_secret_id" "consul_client" {
  accessor_id = consul_acl_token.consul_client.id
}

data "consul_acl_token_secret_id" "consul_mesh_gateway" {
  accessor_id = consul_acl_token.consul_mesh_gateway.id
}

data "consul_acl_token_secret_id" "nomad_server" {
  accessor_id = consul_acl_token.nomad_server.id
}

data "consul_acl_token_secret_id" "nomad_client" {
  accessor_id = consul_acl_token.nomad_client.id
}