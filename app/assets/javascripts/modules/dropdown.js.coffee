define('dropdown', [], ->
  window.Dropdown = class Dropdown
    constructor: (@$el, @options) ->
      @options ||= {on: 'click'}
      @open = false

      unless @options.noListener
        @addEventListener()

    addEventListener: ->
      @$triggerEl = @$el.find('[data-dropdown-trigger]').addBack('[data-dropdown-trigger]')
      @$switchEl  = @$el.find('[data-dropdown-switch]').addBack('[data-dropdown-switch]')
      @$targetEl  = @$el.find('[data-dropdown-target]').addBack('[data-dropdown-target]')

      @$triggerEl.on(@options.on, (event) =>
        if @open
          @closeDropdown(@$targetEl)
        else
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
      if @$switchEl.length > 0
        @handleSwitchEl(@$switchEl, @$triggerEl)
      else
        @handleSwitchEl(@$triggerEl, @$triggerEl)

      @$targetEl.slideToggle(100)

    handleSwitchEl: =>
      @$switchEl.toggleClass('is-active')

      if @$switchEl.data().hasOwnProperty('dropdownSwitchText')
        if @$switchEl.hasClass('is-active')
          @$triggerEl.html('<i class="fa fa-times"></i> Close')
        else
          @$triggerEl.html('<i class="fa fa-search"></i> Search')

  return Dropdown
)
