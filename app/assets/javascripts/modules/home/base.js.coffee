$(document).ready( ->
  $(window).resize( ->
    $('.map--main').css('height', (window.innerHeight/100)*70)
  )

  $(window).trigger('resize')
)
