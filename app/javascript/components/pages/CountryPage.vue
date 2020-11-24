<template>
  <div>
    <div class="card--stats-toggle">
      <tabs-fake
        :children="tabs"
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

    <slot></slot>

    <div class="card--stats-wrapper pdf-break-before">
      <stats-iucn-categories
        :data="activeDatabase.iucn"
      />

      <stats-governance
        :data="activeDatabase.governance"
      />
    </div>

    <stats-sources
      :data="activeDatabase.sources"
    />

    <stats-designations
      :data="activeDatabase.designations"
    />
  </div>
</template>

<script>
import StatsCoverage from '../stats/StatsCoverage.vue'
import StatsDesignations from '../stats/StatsDesignations.vue'
import StatsGovernance from '../stats/StatsGovernance.vue'
import StatsIucnCategories from '../stats/StatsIucnCategories.vue'
import StatsSources from '../stats/StatsSources.vue'
import TabsFake from '../tabs/TabsFake.vue'

export default {
  name: 'CountryPage',

  components: {
    StatsCoverage,
    StatsDesignations,
    StatsGovernance,
    StatsIucnCategories,
    StatsSources,
    TabsFake
  },

  props: {
    data: {
      required: true,
      type: Object
    },
    tabs: {
      required: true,
      type: Array
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