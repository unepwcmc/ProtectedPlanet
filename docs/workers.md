# Workers

Background processing is handled by [Sidekiq](http://sidekiq.org)
workers. As such, the application is dependent on a Redis server running
so that the jobs can be enqueued (though not necessarily processed):

```
redis-server
```

Jobs are processed by running (in two different windows/panes):

```
# 1
bundle exec sidekiq -q default

# 2
bundle exec sidekiq -q import
```

The need for two different sidekiq processes (which also happens in production)
is due to the nature of the WDPA import process. As we completely recreate the
DB at every import, the `import` sidekiq process has to switch connection to a 
new DB, where the import happens. As all sidekiq workers share the same connection 
pool, jobs that are supposed to be running in the current DB (the ones in the `default`
queue) would instead connect to the new unfinished DB.

Having two separate sidekiq processes avoids this issue.

## Status

You can check the status of the current Sidekiq jobs at the route
`/admin/sidekiq`. The username is admin, and the password is available
from the WCMC Informatics password database.

### Wikipedia Articles

**NOTE: Not used anymore - potentially will need to remove these classes**

Each Protected Area has a Wikipedia summary (the first section of a
Wikipedia article) where one can be found.

The Wikipedia Summary worker uses the terrifyingly awful Wikipedia API
to attempt to find articles by searching with the Protected Area name
and designation (e.g. 'Killbear Provincial Park'), and then separately
requesting the article summary.

The documentation for the API seems generally poor, but these links
helped:

* http://en.wikipedia.org/w/api.php
* http://stackoverflow.com/a/8838848/245017
* http://stackoverflow.com/a/8814262/245017

The Wikipedia workers are enqueued during the WDPA import, but can be
run manually for Protected Areas:

```
WikipediaSummaryWorker.perform_async <protected_area_id>
```
