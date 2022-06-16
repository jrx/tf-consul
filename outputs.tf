output "consul_public_ip" {
  value = aws_instance.consul.*.public_ip
}

output "consul_mesh_gateway_public_ip" {
  value = aws_instance.consul_mesh_gateway.*.public_ip
}

output "nomad_server_public_ip" {
  value = aws_instance.nomad_server.*.public_ip
}

output "nomad_client_public_ip" {
  value = aws_instance.nomad_client.*.public_ip
}