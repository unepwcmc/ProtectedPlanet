# Statistics

The app renders three levels of stats: global, regional and country.

## Calculate Statistics

Stats are calculated, and then cached in their respective tables.
`country_statistics` for countries, and `regional_statistics` for
regions and global statistics.

```
bundle exec rake stats:calculate
```
