variable "cluster_name" {
  description = "Name of the cluster."
  default     = "hashi-example"
}

variable "owner" {
  description = "Owner tag on all resources."
  default     = "myuser"
}

variable "key_name" {
  description = "Specify the AWS ssh key to use."
}

variable "private_key" {
  description = "SSH private key to provision the cluster instances."
}

variable "aws_region" {
  default = "eu-north-1"
}

variable "aws_azs" {
  type        = list(any)
  description = "List of the availability zones to use."
  default     = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]
}

variable "amis" {
  type = map(string)
  default = {
    #   eu-north-1 = "ami-026f0eb2e8006617d" # centos 7
    eu-north-1 = "ami-0e201bc52c64d7b5a" # centos 8
  }
}

variable "instance_username" {
  default = "centos"
}

variable "num_vault" {
  description = "Specify the amount of Vault servers. For redundancy you should have at least 2."
  default     = 1
}

variable "num_consul" {
  description = "Specify the amount of Consul servers. For redundancy you should have at least 3."
  default     = 3
}

variable "num_nomad_server" {
  description = "Specify the amount of Nomad servers. For redundancy you should have at least 3."
  default     = 0
}

variable "num_nomad_client" {
  description = "Specify the amount of Nomad clients."
  default     = 0
}

variable "vault_version" {
  default     = "1.6.3"
  description = "Specifies which Vault version instruction to use."
}

variable "consul_version" {
  default     = "1.9.3"
  description = "Specifies which Consul version instruction to use."
}

variable "nomad_version" {
  default     = "1.0.1"
  description = "Specifies which Nomad version instruction to use."
}

variable "vault_instance_type" {
  description = "Vault server instance type."
  default     = "t3.micro"
}

variable "consul_instance_type" {
  description = "Consul server instance type."
  default     = "t3.micro"
}

variable "nomad_server_instance_type" {
  description = "Nomad server instance type."
  default     = "t3.micro"
}

variable "nomad_client_instance_type" {
  description = "Nomad client instance type."
  default     = "t3.micro"
}

variable "consul_license" {
  default     = ""
  description = "Consul license string."
}

variable "consul_gossip_encryption_key" {
  default     = ""
  description = "Consul Gossip encryption string."
}

variable "consul_initial_management_token" {
  default     = ""
  description = "Consul initial management token string."
}