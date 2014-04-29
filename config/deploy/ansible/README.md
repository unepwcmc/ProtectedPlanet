# Ansible

A set of Ansible roles for provisioning a Protected Planet server.

## Usage

Install Ansible locally, add the desired hosts to `./hosts` and run:

```
# Creates a non-root user for use as your permanent login
ansible-playbook -i hosts user.yml

# Installs all required roles
ansible-playbook -i hosts site.yml
```
