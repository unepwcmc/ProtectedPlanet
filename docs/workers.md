# Workers

Background processing is handled by [Sidekiq](http://sidekiq.org)
workers. As such, the application is dependent on a Redis server running
so that the jobs can be enqueued (though not necessarily processed):

```
redis-server
```

Jobs are processed by running:

```
bundle exec sidekiq
```

## Wikipedia Articles

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

## Photos

Protected Areas have photos currently retrieved from Panoramio by
searching the Panoramio API with the Protected Area bounding box.
