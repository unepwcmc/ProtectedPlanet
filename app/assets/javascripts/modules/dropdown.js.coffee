define('dropdown', [], ->
  class Dropdown
    constructor: (@$el, @options) ->
      @options ||= {on: 'click'}
      @addEventListener()

    addEventListener: ->
      $triggerEl = @$el.find('[data-dropdown-trigger]')
        .addBack('[data-dropdown-trigger]')
      $switchEl  = @$el.find('[data-dropdown-switch]')
        .addBack('[data-dropdown-switch]')
      $targetEl  = @$el.find('[data-dropdown-target]')
        .addBack('[data-dropdown-target]')

      $triggerEl.on(@options.on, (event) =>
        if $switchEl.length > 0
          @handleSwitchEl($switchEl, $triggerEl)
        else
          @handleSwitchEl($triggerEl, $triggerEl)

        $targetEl.slideToggle(100)

        event.preventDefault()
      )

    handleSwitchEl: ($switchEl, $triggerEl) ->
      $switchEl.toggleClass('is-active')
      if $switchEl.data().hasOwnProperty('dropdownSwitchText')
        if $switchEl.hasClass('is-active')
          $triggerEl.html("""
            <i class="fa fa-times"></i> Close
          """)
        else
          $triggerEl.html("""
            <i class="fa fa-search"></i> Search
          """)

  return Dropdown
)
