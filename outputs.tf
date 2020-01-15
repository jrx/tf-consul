output "vault_public_ip" {
  value = aws_instance.vault.*.public_ip
}

output "consul_public_ip" {
  value = aws_instance.consul.*.public_ip
}