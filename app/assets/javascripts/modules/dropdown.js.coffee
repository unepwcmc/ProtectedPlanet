define('dropdown', [], ->
  class Dropdown
    constructor: (@$triggerEl, @$el, @options) ->
      if @$triggerEl.length is 0 or @$el.length is 0
        return false

      @options ||= {on: 'click'}
      @render()

    render: ->
      if @$el.prop('tagName') == 'SCRIPT'
        @$el = $(@$el.html())

      @$el.appendTo('body')
      @$el.hide()

      @positionEl()
      @addEventListener()

    hide: ->
      @$el.slideToggle()

    positionEl: ->
      triggerPosition = @$triggerEl.offset()

      @$el.width(@$triggerEl.outerWidth())

      @$el.css('position', 'fixed')
      @$el.css('top', (triggerPosition.top + @$triggerEl.outerHeight()) )
      @$el.css('left', triggerPosition.left)

    addEventListener: ->
      @$triggerEl.on(@options.on, (event) =>
        @$el.stop()
        @positionEl()
        @$triggerEl.toggleClass('active')
        @$el.slideToggle()
        event.preventDefault()
      )

  return Dropdown
)
