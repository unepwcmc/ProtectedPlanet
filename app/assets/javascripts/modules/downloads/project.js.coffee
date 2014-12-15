define('downloads_project', ['downloads_base'], (Base) ->
  class Project extends Base
    constructor: (@type, @opts={}) ->
      super(@type, @opts)
      @domain = 'project'

    submitDownload: (next) =>
      $.post(@constructor.CREATION_PATH, {id: @opts.itemId, domain: @domain}, next)

  return Project
)
