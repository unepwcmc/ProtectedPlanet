//= require vue
//= require d3
//= require vue/charts/Sunburst
//= require vue/charts/Treemap
//= require vue/components/Counter
//= require vue/components/InteractiveTreemap


new Vue({
  el: '.v-marine',
  components: {
    'sunburst': VComponents['vue/charts/Sunburst'],
    'treemap': VComponents['vue/charts/Treemap'],
    'counter': VComponents['vue/components/Counter'],
    'interactive-treemap': VComponents['vue/components/InteractiveTreemap']
  }
})

