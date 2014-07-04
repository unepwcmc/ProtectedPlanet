# Servers and Deployment

## Server Instances

Protected Planet runs on the following AWS EC2 instances.

### Staging

**EC2**

   * Import - m3.xlarge
   * Web -  m3.medium
   * DB - m3.medium

### Production

**EC2**

   * Import - m3.xlarge
   * Web - m3.large
   * DB - m3.large

## Capistrano

Deployments are handled by standard capistrano tasks:

```
cap staging deploy
cap production deploy
```

## Initial Machine Setup

There is a collection of [Ansible](http://ansible.com) scripts in
`config/deploy/ansible` that can be used to provision new servers with
the required stack (Ruby, Postgres, etc).

If you need to install a new dependency on a machine, add some
configuration, etc. you should add an Ansible task/role so that it is
repeatable by anyone.

**If all goes to plan, you should never have to install or configure
anything manually on the server. If you're doing something by hand on
the server, stop it.**

### Provisioning a machine

The only requirement to use Ansible is that you [install the Ansible
binary](http://docs.ansible.com/intro_installation.html). Once
installed, you can add your machine(s) to the host inventory files
(`config/deploy/ansible/inventories/production` and
`config/deploy/ansible/inventories/staging`) and run:

```
cd config/deploy/ansible

# staging
ansible-playbook -i inventories/staging site.yml --ask-vault-pass

# production
ansible-playbook -i inventories/production site.yml --ask-vault-pass
```

This will ask you for a Vault password, which can be found in the
Informatics Password Manager (speak to Stuart Watson for access).

#### Ansible Vault

[Ansible Vault](http://docs.ansible.com/playbooks_vault.html) is used to
protected secret values for servers, such as passwords.

Currently only two files are protected,
[group_vars/staging](../config/deploy/ansible/group_vars/staging) and
[group_vars/production](../config/deploy/ansible/group_vars/production).

You can view or edit these files using the `ansible-vault` command:

```
ansible-vault edit config/deploy/ansible/group_vars/staging
ansible-vault edit config/deploy/ansible/group_vars/production
```

This will ask you for a Vault password, which can be found in the
Informatics Password Manager (speak to Stuart Watson for access).
