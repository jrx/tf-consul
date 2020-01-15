# Vault HA Cluster

## Ansible Development

```sh
ansible-playbook -i "<ip1>," ansible/consul-server.yml
ansible-playbook -i "<ip2>," ansible/consul-client.yml
ansible-playbook -i "<ip2>," ansible/vault-server.yml
```
