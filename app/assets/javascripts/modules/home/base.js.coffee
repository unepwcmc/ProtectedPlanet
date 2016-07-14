$(document).ready( ->
  $(window).resize( ->
    $('.map--main').css('height', (window.innerHeight/100)*70)
  )

  $('.js-close-explore').click( (ev) ->
    $('.js-explore-target').fadeOut()
  )

  $(window).trigger('resize')
)
