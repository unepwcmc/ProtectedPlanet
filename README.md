# Protected Planet Next

## Setup

### Secrets

Some secrets are required by the application, such as AWS keys. Take a
look in [`config/secrets.yml.example`](config/secrets.yml.example) for
the options available, and fill them in as required (probably all of
them). **You will need to copy the `secrets.yml` example file for the
application to run correctly:**

```
  cp config/secrets.yml.example config/secrets.yml
```

## Data

### Initial Seeding

Some data is static and requires seeding if you're starting from an
empty database. For example, the Country and Sub Location list. You can
import these with:

```
rake db:seed
```

## Deployment

### Server Instances

Protected Planet runs on the following AWS EC2 and RDS instances.

#### Staging

**RDS**

   * DB - PostgreSQL with Postgis, db.m3.medium, 30G

**EC2**

   * Import - m3.xlarge
   * Web -  m3.medium

#### Production

**RDS**

   * DB - PostgreSQL with Postgis, db.m3.large, 30G

**EC2**

   * Import - m3.xlarge
   * Web - m3.large

### Capistrano

Deployments are handled by standard capistrano tasks:

```
cap staging deploy
cap production deploy
```

### Initial Machine Setup

There is a collection of [Ansible](http://ansible.com) scripts in
`config/deploy/ansible` that can be used to provision new servers with
the required stack (Ruby, Postgres, etc).

If you need to install a new dependency on a machine, add some
configuration, etc. you should add an Ansible task/role so that it is
repeatable by anyone.

**If all goes to plan, you should never have to install or configure
anything manually on the server. If you're doing something by hand on
the server, stop it.**

#### Provisioning a machine

The only requirement to use Ansible is that you [install the Ansible
binary](http://docs.ansible.com/intro_installation.html). Once
installed, you can add your machine(s) to `config/deploy/ansible/hosts`
and run:

```
cd config/deploy/ansible
ansible-playbook -i hosts site.yml
```
