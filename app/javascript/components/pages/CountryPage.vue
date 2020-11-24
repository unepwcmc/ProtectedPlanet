<template>
  <div>
    <div class="card--stats-toggle">
      <tabs-fake
        :children="[{ id: 'wdpa', title: 'Protected Areas' }, { id: 'wdpa_oecm', title: 'Protected Areas & OECMs' }]"
        class="tabs--rounded"
        v-on:click:tab="updateDatabaseId"
      ></tabs-fake>
    </div>

    <div class="card--stats-wrapper">
      <stats-coverage
        v-for="stat in activeDatabase.coverage"
        :key="stat._uid"
        :data="stat"
      />
    </div>
  </div>
</template>

<script>
import StatsCoverage from '../stats/StatsCoverage.vue'
import TabsFake from '../tabs/TabsFake.vue'

export default {
  name: 'CountryPage',

  components: {
    StatsCoverage,
    TabsFake
  },

  props: {
    data: {
      required: true,
      type: Object
    }
  },

  data () {
    return  {
      databaseId: 'wdpa'
    }
  },

  computed: {
    activeDatabase () {
      return this.data[this.databaseId]
    }
  },

  mounted () {
    this.databaseId = 'wdpa'
  },

  methods: {
    updateDatabaseId (id) {
      this.databaseId = id
    }
  }
}
</script>