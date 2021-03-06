# Deployment

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

Currently only one file is protected,
[group_vars/db](../config/deploy/ansible/group_vars/db).

You can view or edit this file using the `ansible-vault` command:

```
ansible-vault edit config/deploy/ansible/group_vars/db
```

This will ask you for a Vault password, which can be found in the
Informatics Password Manager (speak to Stuart Watson for access).

## Maintenance Mode

Servers can be put in to maintenance mode to restrict access to the
site during deploys, maintenance, etc. This state is handled by the
`AdminController`, and is secured by a `maintenance_mode_key` in in the
`secrets.yml` config file.

### Manually

If you need to turn on maintenance mode from a different server, as the
Utility box has to do during an import, you can do so via HTTP:

```
# On
curl -X PUT -d maintenance_mode_on=true --header "X-Auth-Key: <key>" <domain>/admin/maintenance
# Off
curl -X PUT -d maintenance_mode_on=false --header "X-Auth-Key: <key>" <domain>/admin/maintenance
```

### Capistrano

If you need to turn maintenance mode on manually, you can use
capistrano:

```
# On
cap <stage> maintenance:on
# Off
cap <stage> maintenance:off
```
