define('cms:tracked_download_links', [], ->
  class TrackedDownloadLinks
    @initialize: ($tracked_links) ->
      new TrackedDownloadLinks($tracked_links).initialize()

    constructor: (@$tracked_links) ->

    initialize: ->
      @$tracked_links.each((n, link) ->
        label = link.dataset.track

        link.addEventListener('click', ->
          if ga?
            ga('send', 'event', "Downloads - CMS", 'click', label)
        )
      )
)
