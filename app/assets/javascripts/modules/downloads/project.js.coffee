define('downloads_project', ['downloads_base'], (Base) ->
  class Project extends Base
    constructor: (@type, @opts={}) ->
      super(@type, @opts)
      @domain = 'project'

    submitDownload: (next) =>
      @trackDownload("Submit - #{@type}", @opts.itemId)
      $.post(@constructor.CREATION_PATH, {AUTH_TOKEN: @authToken, id: @opts.itemId, domain: @domain}, next)

    trackDownloadClick: (ev) =>
      @trackDownload("Download Click - #{@type}", @opts.itemId)

  return Project
)
