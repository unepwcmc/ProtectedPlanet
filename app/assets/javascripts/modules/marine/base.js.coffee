$(document).ready( ->

  # generate map at the top of the page
  require(['map'], (Map) ->
    mapMarine = new Map($('#map-marine'))
    mapMarine.render()
  )

  # generate a new vue instance and initialise all the vue components on the page
  
)