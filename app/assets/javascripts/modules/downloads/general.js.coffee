define('downloads_general', ['downloads_base'], (Base) ->
  class General extends Base
    constructor: (@type, @opts={}) ->
      super(@type, @opts)
      @domain = 'general'
      @completedDownloadTemplate = -> $('#general-download-complete-modal-template').html()

    submitDownload: (next) ->
      $.post(@constructor.CREATION_PATH, {id: @opts.itemId, domain: @domain}, next)

    completed: ->
      true

  return General
)
