# Protected Planet

>
> If you are reading here for very first time we reccomend you to read [Protected Planet WIKI](https://github.com/unepwcmc/protected-planet-wiki) to understand the PP family/architechture
>

 

You can check out the previous version of Protected Planet on
[GitHub](https://github.com/unepwcmc/ppe).

> **TO DEVELOPERS - All protected planet family apps in one same place:** For VSCode users, clone [ProtectedPlanet](https://github.com/unepwcmc/ProtectedPlanet) repo and read/use [protected-planet-family-apps.code-workspace](https://github.com/unepwcmc/ProtectedPlanet/blob/master/protected-planet-family-apps.code-workspace) to see all protected planet family apps in the same workspace and its repository links. To access the data-management-portal realted apps please read [pp-data-management-portal](https://github.com/unepwcmc/pp-data-management-portal).


## Topics

When you clone this repo please do it recursively. For the first time:
```
git clone --recurse-submodules
```

If you already cloned it:
```
git submodule update --init --recursive
```

1. [Getting Started and Configuration with Docker](docs/docker.md)
    * [Setup Without Docker - not recommended and outdated](docs/installation.md)
2. [Release Process (Sync Data Management Portal Data to Protected Planet)](docs/release/release_process.md)
    * [Release Data Imports](docs/release/release_data_imports.md) - What data is imported during a release
3. [Deployment](docs/deployment.md)
4. [Development workflow, conventions and tips](docs/workflow.md)
5. [Search](docs/search.md)
6. [Background Workers](docs/workers.md)
7. [Downloads](docs/downloads.md)
9. [Caching](docs/caching.md)
10. [CMS](docs/cms.md)
11. [Relationships between Protected Areas and Parcels](docs/protected_area_parcels.md)
12. [Green List Functionality](docs/green_list.md)
13. [DB Connection between PP and Data Management Portal (FDW) Setup](docs/fdw_setup/index.md)
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
