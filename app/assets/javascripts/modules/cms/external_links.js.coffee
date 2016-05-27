define('cms:external_links', [], ->
  class ExternalLinks
    @initialize: ($links) ->
      new ExternalLinks($links).initialize()

    constructor: (@$links) ->

    initialize: ->
      @$links.each((i, link) ->
        if link.host != document.location.host
          $(link).addClass('is-external')
      )
)


