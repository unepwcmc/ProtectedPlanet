define('dropdown', [], ->
  window.Dropdown = class Dropdown
    constructor: (@$el, @options) ->
      @options ||= {on: 'click'}
      @open = false

      unless @options.noListener
        @addEventListener()

    addEventListener: ->
      @$triggerEl = @$el.find('.js-trigger').addBack('.js-trigger')
      @$switchEl  = @$el.find('.js-switch').addBack('.js-switch')
      @$targetEl  = @$el.find('.js-target').addBack('.js-target')

      @$triggerEl.on(@options.on, (event) =>
        if @open
          @$triggerEl.toggleClass('is-open')
          @closeDropdown(@$targetEl)
        else
          @$triggerEl.toggleClass('is-open')
          @closeOtherDropdowns()
          @openDropdown(@$targetEl)

        event.preventDefault()
      )

    closeOtherDropdowns: ->
      for dropdown in UiState.dropdowns
        dropdown.closeDropdown()
      UiState.dropdowns = []

    openDropdown: =>
      @open = true
      @toggleDropdown()
      UiState.dropdowns.push(@)

    closeDropdown: =>
      @open = false
      @toggleDropdown()

      dropdownIndex = UiState.dropdowns.indexOf(@)
      UiState.dropdowns.splice(dropdownIndex, 1)

    toggleDropdown: =>
      @handleSwitchEl() if @$switchEl.length > 0
      @$targetEl.slideToggle(100)

    handleSwitchEl: =>
      @$switchEl.toggleClass('is-active')

      if @$switchEl.data()?.hasOwnProperty('dropdownSwitchText')
        if @$switchEl.hasClass('is-active')
          @$triggerEl.html('<i class="fa fa-times"></i>')
        else
          @$triggerEl.html('<i class="fa fa-search"></i>')

  return Dropdown
)
