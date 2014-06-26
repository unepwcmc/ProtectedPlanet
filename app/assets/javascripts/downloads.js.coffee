class @DownloadModal
  DEFAULT_TYPES = ['csv', 'shp', 'kml']
  BASE_DOWNLOAD_PATH = '/downloads'

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
    @$el = $(@constructor.template)
    @$el.find('#close-modal').on('click', (e) =>
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

  hide: ->
    @$el.removeClass('opened')
