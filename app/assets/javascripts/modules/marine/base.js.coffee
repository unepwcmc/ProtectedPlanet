$(document).ready( ->

  #generate map at the top of the page
  require(['map'], (Map) ->
    mapMarine = new Map($('#map-marine'))
    mapMarine.render()
  )

  #generate a new vue instance and initialise all the vue components on the page
  new Vue({
    el: '.v-marine',
    components: {
      'sunburst': VComponents['vue/charts/Sunburst'],
      'treemap': VComponents['vue/charts/Treemap'],
      'counter': VComponents['vue/components/Counter'],
      'interactive-treemap': VComponents['vue/components/InteractiveTreemap']
    }
  })
)