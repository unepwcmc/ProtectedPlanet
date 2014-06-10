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

### WDPA Setup

See below for instructions on Importing to Rails. 

## Data

### Initial Seeding

Some data is static and requires seeding if you're starting from an
empty database. For example, the Country and Sub Location list. You can
import these with:

```
rake db:seed
```

