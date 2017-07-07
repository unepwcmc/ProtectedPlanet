define('show_hide', [], ->
  class ShowHide
    constructor: (@$button) ->
      @setup()
      @addEventListeners()

    setup: () ->
      $wrappers = @$button.parents('.js-show-hide-wrapper')

      $.each($wrappers, (index, wrapper) =>
        $wrapper = $(wrapper)

        $cards = $wrapper.find('.js-show-hide-target')

        @hideCards($cards)

        if($cards.length < 7) 
          $wrapper.find('.js-show-hide').addClass('u-hide')
      )

    addEventListeners: () ->
      @$button.on('click', (e) =>
        $clicked = $(e.target)
        $wrapper = $clicked.parents('.js-show-hide-wrapper')
        $cards = $wrapper.find('.js-show-hide-target')  

        type = $clicked.data('type')

        if(type == 'show')
          $.each($cards, (index, card)->
            $(card).removeClass('u-hide')
          )

          $clicked.data('type', 'hide')
          $clicked.text('Hide')

        else
          @hideCards($cards)

          $clicked.data('type', 'show')
          $clicked.text('Show all')
      )

    hideCards: (cards) ->
      $cardsToHide = cards.slice(6)

      $.each($cardsToHide, (index, card) ->
        $(card).addClass('u-hide')
      )

  return ShowHide
)