<template>
  <div>
    <tabs-fake
      :children="[{ id: 'wdpa', title: 'Protected Areas' }, { id: 'wdpaoecm', title: 'Protected Areas & OECMs' }]"
      class="tabs--rounded"
      v-on:click:tab="changeTab"
    ></tabs-fake>
  </div>
</template>

<script>
export default {
  name: 'ChartToggle',
  
  props: {
    tabs: {
      required: true,
      type: Array
    }
  },

  methods: {
    changeTab (id) {
      console.log(id)
      this.$store.dispatch('data/updateDataSourceId', id)
    }
  }
}
</script>