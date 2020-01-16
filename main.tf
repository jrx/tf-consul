provider "aws" {
  region = var.aws_region
}

terraform {
  required_version = ">= 0.12"
  backend "remote" {}
}

resource "aws_instance" "vault" {
  ami                         = var.amis[var.aws_region]
  instance_type               = var.vault_instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = ["${aws_security_group.default.id}"]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.consul_profile.name
  count                       = var.num_vault

  availability_zone = module.vpc.azs[count.index % length(module.vpc.azs)]
  subnet_id         = module.vpc.public_subnets[count.index % length(module.vpc.azs)]

  provisioner "remote-exec" {
    inline = [
      "mkdir /home/${var.instance_username}/ansible",
    ]
  }
  provisioner "file" {
    source      = "./ansible/"
    destination = "/home/${var.instance_username}/ansible/"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo yum -y install ansible",
      "cd ansible; ansible-playbook -c local -i \"localhost,\" -e 'JOIN_TAG=${var.cluster_name} BIND_ADDR=${self.private_ip} NODE_NAME=consul-c${count.index}' consul-client.yml",
    ]
  }
  provisioner "remote-exec" {
    inline = [
      "sudo yum -y install ansible",
      "cd ansible; ansible-playbook -c local -i \"localhost,\" -e 'ADDR=${self.private_ip} NODE_NAME=vault-s${count.index}' vault-server.yml",
    ]
  }

  connection {
    host        = coalesce(self.public_ip, self.private_ip)
    type        = "ssh"
    user        = var.instance_username
    private_key = var.private_key
  }

  tags = {
    Name  = "${var.cluster_name}-vault-${count.index}"
    Owner = var.owner
    # Keep = ""
    Consul = "${var.cluster_name}"
  }
}

resource "aws_instance" "consul" {
  ami                    = var.amis[var.aws_region]
  instance_type          = var.consul_instance_type
  key_name               = var.key_name
  vpc_security_group_ids = ["${aws_security_group.default.id}"]
  iam_instance_profile   = aws_iam_instance_profile.consul_profile.name
  count                  = var.num_consul

  availability_zone = module.vpc.azs[count.index % length(module.vpc.azs)]
  subnet_id         = module.vpc.public_subnets[count.index % length(module.vpc.azs)]

  provisioner "remote-exec" {
    inline = [
      "mkdir /home/${var.instance_username}/ansible",
    ]
  }
  provisioner "file" {
    source      = "./ansible/"
    destination = "/home/${var.instance_username}/ansible/"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo yum -y install ansible",
      "cd ansible; ansible-playbook -c local -i \"localhost,\" -e 'JOIN_TAG=${var.cluster_name} ADVERTISE_ADDR=${self.private_ip} BOOTSTRAP_EXPECT=${var.num_consul} NODE_NAME=consul-s${count.index}' consul-server.yml",
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
    Consul = "${var.cluster_name}"
  }
}


