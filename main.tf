provider "aws" {
  region = var.aws_region
}

resource "aws_kms_key" "vault" {
  description             = "Vault unseal key"
  deletion_window_in_days = 10

  tags = {
    Name = "${var.cluster_name}-vault-key"
  }
}

resource "aws_instance" "vault" {
  ami                         = var.amis[var.aws_region]
  instance_type               = var.vault_instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.default.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.vault_profile.id
  count                       = var.num_vault

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
      "cd ansible; ansible-playbook -c local -i \"localhost,\" -e 'JOIN_TAG=${var.cluster_name} BIND_ADDR=${self.private_ip} NODE_NAME=consul-c${count.index} CONSUL_LICENSE=${var.consul_license} CONSUL_VERSION=${var.consul_version}' consul-client.yml",
    ]
  }
  # provisioner "remote-exec" {
  #   inline = [
  #     "cd ansible; ansible-playbook -c local -i \"localhost,\" -e 'ADDR=${self.private_ip} NODE_NAME=vault-s${count.index} VAULT_VERSION=${var.vault_version} KMS_KEY=${aws_kms_key.vault.id} AWS_REGION=${var.aws_region}' vault-server.yml",
  #   ]
  # }

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
    Consul = var.cluster_name
  }
}

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
      "cd ansible; ansible-playbook -c local -i \"localhost,\" -e 'JOIN_TAG=${var.cluster_name} ZONE=${self.availability_zone} ADVERTISE_ADDR=${self.private_ip} BOOTSTRAP_EXPECT=${var.num_consul} NODE_NAME=consul-s${count.index} CONSUL_LICENSE=${var.consul_license} CONSUL_VERSION=${var.consul_version}' consul-server.yml",
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

resource "aws_instance" "nomad_server" {
  ami                         = var.amis[var.aws_region]
  instance_type               = var.nomad_server_instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.default.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.consul_profile.name
  count                       = var.num_nomad_server

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
      "cd ansible; ansible-playbook -c local -i \"localhost,\" -e 'JOIN_TAG=${var.cluster_name} BIND_ADDR=${self.private_ip} NODE_NAME=nomad-s${count.index} CONSUL_LICENSE=${var.consul_license} CONSUL_VERSION=${var.consul_version}' consul-client.yml",
    ]
  }
  provisioner "remote-exec" {
    inline = [
      "cd ansible; ansible-playbook -c local -i \"localhost,\" -e 'NOMAD_VERSION=${var.nomad_version} BOOTSTRAP_EXPECT=${var.num_nomad_server} SERVER_ENABLED=true CLIENT_ENABLED=false' nomad.yml",
    ]
  }

  connection {
    host        = coalesce(self.public_ip, self.private_ip)
    type        = "ssh"
    user        = var.instance_username
    private_key = var.private_key
  }

  tags = {
    Name  = "${var.cluster_name}-nomad-server-${count.index}"
    Owner = var.owner
    # Keep = ""
    Consul = var.cluster_name
  }
}

resource "aws_instance" "nomad_client" {
  ami                         = var.amis[var.aws_region]
  instance_type               = var.nomad_client_instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.default.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.consul_profile.name
  count                       = var.num_nomad_client

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
      "cd ansible; ansible-playbook -c local -i \"localhost,\" -e 'JOIN_TAG=${var.cluster_name} BIND_ADDR=${self.private_ip} NODE_NAME=nomad-s${count.index} CONSUL_VERSION=${var.consul_version}' consul-client.yml",
    ]
  }
  provisioner "remote-exec" {
    inline = [
      "cd ansible; ansible-playbook -c local -i \"localhost,\" -e 'NOMAD_VERSION=${var.nomad_version} BOOTSTRAP_EXPECT=${var.num_nomad_client} SERVER_ENABLED=false CLIENT_ENABLED=true' nomad.yml",
    ]
  }

  connection {
    host        = coalesce(self.public_ip, self.private_ip)
    type        = "ssh"
    user        = var.instance_username
    private_key = var.private_key
  }

  tags = {
    Name  = "${var.cluster_name}-nomad-client-${count.index}"
    Owner = var.owner
    # Keep = ""
    Consul = var.cluster_name
  }
}