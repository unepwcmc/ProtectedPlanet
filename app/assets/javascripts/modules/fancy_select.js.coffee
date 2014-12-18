class window.FancySelect
  @template: """
    <div>
      <ul></ul>
    </div>
  """

  constructor: (@options) ->
    @$selectEl = $(@options.selectEl)
    @$selectEl.hide()

    @render(options)

  selectOptions: ->
    optionEls = $.makeArray(@$selectEl.find('option'))

    return optionEls.map((optionEl) =>
      $optionEl = $(optionEl)
      return {
        value: $optionEl.attr('value')
        text: $optionEl.text()
      }
    )

  selectedItemText: ->
    return @$selectEl.find('option:selected').text()

  render: (options) ->
    @$el = $(@constructor.template)

    @addTitle() if options.withTitle?
    @addOptions()
    @addClasses()
    @addEventListeners()

    @$selectEl.after(@$el)
    return @

  addTitle: ->
    @$el.prepend("""<h6></h6><i class="icon-chevron-down"></i>""")
    @$el.find('h6').html(@selectedItemText())


  addOptions: ->
    @$el.find('ul').html(@selectOptions().map( (option) ->
      "<li value='#{option.value}'>#{option.text}</li>"
    ).join('\n'))

  addClasses: ->
    selectClass = @$selectEl.attr('class')
    @$el.addClass(selectClass)
    @$el.addClass('fancy-select')
    @$el.addClass(@options.customClass) if @options.customClass

  addEventListeners: ->
    @$el.find('li').click(@updateSelect)

  updateSelect: (event) =>
    $itemEl = $(event.target)
    @$selectEl.val($itemEl.attr('value'))
    @$selectEl.trigger('change')

  @fancify: (container)->
    selectEls = $(container).find('.fancy-select')

    $.makeArray(selectEls).forEach((selectEl) ->
      new FancySelect(selectEl: selectEl)
    )
