//= require vue
//= require d3
//= require vue/charts/Sunburst
//= require vue/test/Incrementor

new Vue({
  el: '.v-marine',
  components: {
    'sunburst': VComponents['charts/Sunburst'],
    'incrementor': VComponents['vue/test/Incrementor']
  }
})

