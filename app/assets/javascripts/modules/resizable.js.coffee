define('resizable', [], ->
  class Resizable
    @initialize: ($resizableEls) ->
      new Resizable($resizableEls).initialize()

    constructor: (@$resizableEls) ->

    initialize: ->
      @$resizableEls.each( (i, resizableEl) =>
        @addEventListener($(resizableEl))
      )

    addEventListener: ($resizableEl) ->
      mobileHeight = $resizableEl.data("mobile-height")
      desktopHeight = $resizableEl.data("desktop-height")
      resizableId = $resizableEl.attr("id")

      $(window).resize( =>
        resized = @resize($resizableEl, mobileHeight, desktopHeight)

        if resized and resizableId of window.ProtectedPlanet.Maps
          window.ProtectedPlanet.Maps[resizableId].instance.invalidateSize()
      )

      $(window).trigger("resize")

    resize: ($el, mobile, desktop) ->
      currentWidth = window.innerWidth

      if currentWidth <= 768 and mobile
        $el.css("height", (window.innerHeight/100)*mobile)
        return true
      else if currentWidth > 768 and desktop
        $el.css("height", (window.innerHeight/100)*desktop)
        return true
      else
        return false
)
