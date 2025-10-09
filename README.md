# Protected Planet

[![Build Status](https://travis-ci.org/unepwcmc/ProtectedPlanet.svg)](https://travis-ci.org/unepwcmc/ProtectedPlanet)
[![Code Climate](https://codeclimate.com/repos/539b16466956806b20010ddc/badges/e90cf6ba84f66503705c/gpa.svg)](https://codeclimate.com/repos/539b16466956806b20010ddc/feed)
[![Test Coverage](https://codeclimate.com/repos/539b16466956806b20010ddc/badges/e90cf6ba84f66503705c/coverage.svg)](https://codeclimate.com/repos/539b16466956806b20010ddc/feed)

You can check out the previous version of Protected Planet on
[GitHub](https://github.com/unepwcmc/ppe).

## Topics

When you clone this repo please do it recursively. For the first time:
```
git clone --recurse-submodules
```

If you already cloned it:
```
git submodule update --init --recursive
```

1. [Getting Started and Configuration](docs/installation.md)
    * [Docker Setup](docs/docker.md)
2. [Importing and Managing the WDPA](docs/wdpa.md)
    * [Automatic Import](docs/automatic_import.md)
3. [Deployment](docs/deployment.md)
4. [Development workflow, conventions and tips](docs/workflow.md)
5. [Search](docs/search.md)
6. [Background Workers](docs/workers.md)
7. [Downloads](docs/downloads.md)
8. [Statistics](docs/statistics.md)
9. [Caching](docs/caching.md)
10. [CMS](docs/cms.md)
11. [Relationships between Protected Areas and Parcels](docs/protected_area_parcels.md)
12. [Green List Functionality](docs/green_list.md)
13. [Portal Release Runbook](docs/portal_release_runbook.md)
14. [Banner system](docs/banner_system.md)
## Licence

Protected Planet is released under the [BSD
3-Clause](http://opensource.org/licenses/BSD-3-Clause) License.

## Local (after setup) 

### Run application (within separate tabs)
1. `elasticsearch`
1. `redis-server`
1. `./bin/webpack-dev-server`
1. `rails s`
