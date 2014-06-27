class @DownloadModal
  DEFAULT_TYPES = ['csv', 'shp', 'kml']
  BASE_DOWNLOAD_PATH = '/downloads'

  @overlayTemplate: "<div class=\"total-overlay\"></div>"

  @template: """
    <div id="download-modal">
      <h3>Select a download type</h3>
      <section>
        <div id="link-container"></div>
        <p>…or use the ESRI web service</p>
      </section>
      <div>
        <a href="#" id="close-modal" class="btn btn-primary">Cancel</a>
      </div>
    </div>
  """

  constructor: ->
    @$overlay = $(@constructor.overlayTemplate)
    @$el = $(@constructor.template)

    for el in [@$overlay, @$el.find('#close-modal')]
      el.on('click', (e) =>
        @hide()
        e.preventDefault()
      )

  buildLinksFor: (objectName, types) ->
    types ||= DEFAULT_TYPES
    linkContainer = @$el.find('#link-container')

    newLinks = types.map((type) ->
      typeLinkText = type.toUpperCase()
      typeLinkHref = "#{BASE_DOWNLOAD_PATH}/#{objectName}?type=#{type}"

      newLink = "<a class=\"btn btn-primary\" href=\"#{typeLinkHref}\">#{typeLinkText}</a>"
      newLink
    )

    linkContainer.html(newLinks)

  show: ->
    @$el.addClass('opened')
    @$overlay.addClass('visible')

  hide: ->
    @$el.removeClass('opened')
    @$overlay.removeClass('visible')
