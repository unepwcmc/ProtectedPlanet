<template>
  <div class="v-interactive-treemap flex-row-wrap justify-content-end">
    <div class="flex-2-thirds">
      <treemap></treemap>
    </div>

    <div class="flex-1-third">
      <h3 class="header--small">Percent of national waters covered by Protected Areas</h3>
      <!-- <p class="text--120"><incrementor :total="14.4"></incrementor>%</p> -->

      <h3 class="header--small">Total Area Protected</h3>
      <p class="text--48"><increment :total="20399820"></increment>km²</p>
      <increment :total="10"></increment>
      <sunburst></sunburst>
    </div>
  </div>
</template>

<script>
  module.exports = {
    name: 'interactive-treemap',

    components: { 
      'treemap': VComponents['vue/charts/Treemap'],
      'sunburst': VComponents['vue/charts/Sunburst'],
      'increment': VComponents['vue/components/Increment']
    }
  }  
</script>
