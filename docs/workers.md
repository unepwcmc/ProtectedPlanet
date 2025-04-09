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