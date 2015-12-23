define('dropdown', [], ->
  class Dropdown
    constructor: (@$triggerEl, @$el, @options) ->
      if @$triggerEl.length is 0 or @$el.length is 0
        return false

      @options ||= {on: 'click'}
      @addEventListener()

    addEventListener: ->
      @$triggerEl.on(@options.on, (event) =>
        @$triggerEl.toggleClass('active')
        @$el.slideToggle(100)
        event.preventDefault()
      )

  return Dropdown
)
