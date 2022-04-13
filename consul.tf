resource "aws_instance" "consul" {
  ami                    = var.amis[var.aws_region]
  instance_type          = var.consul_instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.default.id]
  iam_instance_profile   = aws_iam_instance_profile.consul_profile.name
  count                  = var.num_consul

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
      "cd ansible; ansible-playbook -c local -i \"localhost,\" -e 'JOIN_TAG=${var.cluster_name} ZONE=${self.availability_zone} ADVERTISE_ADDR=${self.private_ip} BOOTSTRAP_EXPECT=${var.num_consul} NODE_NAME=consul-s${count.index} CONSUL_LICENSE=${var.consul_license} CONSUL_GOSSIP_ENCRYPTION_KEY=${var.consul_gossip_encryption_key} CONSUL_INITIAL_MANAGEMENT_TOKEN=${var.consul_initial_management_token} CONSUL_VERSION=${var.consul_version}' consul-server.yml",
    ]
  }

  connection {
    host        = coalesce(self.public_ip, self.private_ip)
    type        = "ssh"
    user        = var.instance_username
    private_key = var.private_key
  }

  tags = {
    Name  = "${var.cluster_name}-consul-${count.index}"
    Owner = var.owner
    # Keep = ""
    Consul = var.cluster_name
  }
}