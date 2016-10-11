$(document).ready( ->
  $(window).resize( ->
    if window.innerWidth <= 768
      $('.map--main').css('height', (window.innerHeight/100)*40)
    else
      $('.map--main').css('height', (window.innerHeight/100)*70)

  )

  $(window).trigger('resize')
)
