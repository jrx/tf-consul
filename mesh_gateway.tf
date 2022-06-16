resource "aws_instance" "consul_mesh_gateway" {
  ami                         = var.amis[var.aws_region]
  instance_type               = var.consul_mesh_gateway_instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.default.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.consul_profile.name
  count                       = var.num_consul_mesh_gateway

  availability_zone = data.terraform_remote_state.vpc.outputs.aws_azs[count.index % length(data.terraform_remote_state.vpc.outputs.aws_azs)]
  subnet_id         = data.terraform_remote_state.vpc.outputs.aws_public_subnets[count.index % length(data.terraform_remote_state.vpc.outputs.aws_azs)]


  provisioner "remote-exec" {
    inline = [
      "sudo yum -y install epel-release",
      "sudo yum -y install ansible",
      "mkdir /home/${var.instance_username}/ansible",
    ]
  }
  provisioner "file" {
    source      = "./ansible/"
    destination = "/home/${var.instance_username}/ansible/"
  }
  provisioner "remote-exec" {
    inline = [
      "cd ansible; ansible-playbook -c local -i \"localhost,\" -e 'JOIN_TAG=${var.cluster_name} BIND_ADDR=${self.private_ip} NODE_NAME=consul-mgw${count.index} CONSUL_LICENSE=${var.consul_license} CONSUL_GOSSIP_ENCRYPTION_KEY=${var.consul_gossip_encryption_key} CONSUL_CLIENT_TOKEN=${nonsensitive(data.consul_acl_token_secret_id.consul_client.secret_id)} CONSUL_VERSION=${var.consul_version}' consul-client.yml",
    ]
  }
  provisioner "remote-exec" {
    inline = [
      "cd ansible; ansible-playbook -c local -i \"localhost,\" -e 'ENVOY_VERSION=${var.envoy_version} CONSUL_MESH_GATEWAY_TOKEN=${nonsensitive(data.consul_acl_token_secret_id.consul_mesh_gateway.secret_id)} PUBLIC_IP=${self.public_ip}' consul-mesh-gateway.yml",
    ]
  }

  connection {
    host        = coalesce(self.public_ip, self.private_ip)
    type        = "ssh"
    user        = var.instance_username
    private_key = var.private_key
  }

  tags = {
    Name  = "${var.cluster_name}-consul-mesh-gateway-${count.index}"
    Owner = var.owner
    # Keep = ""
    Consul = var.cluster_name
  }
}