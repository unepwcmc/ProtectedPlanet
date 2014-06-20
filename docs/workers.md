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

## Assets

Importing assets for Protected Areas tends to be quite time consuming as
they contact external services. As such they have associated workers
that retrieve content in the background.

Asset importing is done during the WDPA import, but you can start it
manually:

```
Wdpa::ProtectedAreaImporter::AssetImporter.import
```

### Wikipedia Articles

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

### Photos

Protected Areas have photos currently retrieved from Panoramio by
searching the Panoramio API with the Protected Area bounding box.

The photo downloading workers are enqueued during the WDPA import, but
can be run manually for Protected Areas:

```
ImageWorker.perform_async <protected_area_id>
```
