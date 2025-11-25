# Workers

Background processing is handled by [Sidekiq](http://sidekiq.org)
workers. As such, the application is dependent on a Redis server running
so that the jobs can be enqueued (though not necessarily processed):

```
redis-server
```

## Current Setup

Jobs are processed by running:

```
bundle exec sidekiq -q default
```

> **Note**: As of 24 November 2025, the `import` queue is no longer used for monthly releases. We now use the portal importer for releases. The import queue workers are legacy code that may be removed in the future.

For monthly releases, see the [Release Process Documentation](release/release_process.md) and [Portal Release Runbook](release/portal_release_runbook.md).

## Legacy Import Workers

The following information is kept for reference only, as the old import worker system is deprecated:

**Historical Context**: Previously, two separate sidekiq processes were needed:
- `default` queue - Regular application jobs
- `import` queue - WDPA import jobs

This was necessary because the old import process completely recreated the database at every import. The `import` sidekiq process had to switch connection to a new DB where the import happened. Since all sidekiq workers share the same connection pool, jobs in the `default` queue would have connected to the unfinished import DB. Having two separate sidekiq processes avoided this issue.

## Status

You can check the status of the current Sidekiq jobs at the route
`/admin/sidekiq`. The username is admin, and the password is available
from the WCMC Informatics password database.