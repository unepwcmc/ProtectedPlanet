define('tabs', [], ->
  class Tabs
    constructor: (@$container, next) ->
      @addEventListeners(next)

    addEventListeners: (next) ->
      @$container.find('.js-tab-title').on('click', (e) =>
        $clicked = $(e.target)

        @updateActiveTabTitle($clicked)
        activeTabContent = @updateActiveTabContent($clicked)
        next($clicked, activeTabContent) if(typeof next != 'undefined')
      )

    updateActiveTabTitle: (tabTitle) ->
      @$container.find('.js-tab-title').removeClass('tab__title--active')
      @$container.find(tabTitle).addClass('tab__title--active')

    updateActiveTabContent: (id) ->
      tabContentSelector = "[data-id='#{$(id).data('id')}-content']"

      @$container.find('.js-tab-content').addClass('u-hide')
      activeTabContent = @$container.find($(tabContentSelector))
      activeTabContent.removeClass('u-hide')

      activeTabContent

  return Tabs
)
