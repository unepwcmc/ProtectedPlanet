<template>
  <div>
    <div 
      class="card--stats-toggle"
      v-if="tabs.length > 1"
    >
      <tabs-fake
        :children="tabs"
        class="tabs--rounded"
        v-on:click:tab="updateDatabaseId"
      ></tabs-fake>
    </div>

    <div 
      class="card--stats-wrapper"
      v-if="data.coverage"
    >
      <stats-coverage
        v-for="stat in activeDatabase.coverage"
        :key="stat._uid"
        :data="stat"
      />
    </div>

    <stats-message
      :data="activeDatabase.message"
    />

    <div class="card--stats-wrapper pdf-break-before">
      <stats-iucn-categories
        :data="activeDatabase.iucn"
      />

      <stats-governance
        :data="activeDatabase.governance"
      />
    </div>

    <stats-sources
      v-if="activeDatabase.sources"
      v-bind="{
        count: activeDatabase.sources.count,
        title: activeDatabase.sources.title,
        sourceUpdated: activeDatabase.sources.source_updated,
        sources: activeDatabase.sources.sources
      }"
    />

    <stats-designations
      :data="activeDatabase.designations"
    />

    <stats-growth
      :data="activeDatabase.growth"
    />

    <slot name="related_countries" />

    <stats-sites
      :data="activeDatabase.sites"
    />
  </div>
</template>

<script>
import StatsCoverage from '../stats/StatsCoverage.vue'
import StatsDesignations from '../stats/StatsDesignations.vue'
import StatsGovernance from '../stats/StatsGovernance.vue'
import StatsGrowth from '../stats/StatsGrowth.vue'
import StatsIucnCategories from '../stats/StatsIucnCategories.vue'
import StatsMessage from '../stats/StatsMessage.vue'
import StatsSites from '../stats/StatsSites.vue'
import StatsSources from '../stats/StatsSources.vue'
import TabsFake from '../tabs/TabsFake.vue'

export default {
  name: 'CountryPage',

  components: {
    StatsCoverage,
    StatsDesignations,
    StatsGovernance,
    StatsGrowth,
    StatsMessage,
    StatsIucnCategories,
    StatsSites,
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