define('dropdown', [], ->
  class Dropdown
    constructor: (@$el, @options) ->
      return false if @$el.length is 0

      @$triggerEl = @$el.find('.js-trigger')
      @$targetEl  = @$el.find('.js-target')

      @options ||= {on: 'click'}
      @addEventListener()

    addEventListener: ->
      @$triggerEl.on(@options.on, (event) =>
        event.preventDefault()

        @$triggerEl.toggleClass('active')
        @$targetEl.slideToggle(100)
      )

  return Dropdown
)
