define('downloads_general', ['downloads_base'], (Base) ->
  class General extends Base
    constructor: (@type, @opts={}) ->
      super(@type, @opts)
      @domain = 'general'

    submitDownload: (next) ->
      $.post(@constructor.CREATION_PATH, {id: @opts.itemId, domain: @domain}, next)

  return General
)
