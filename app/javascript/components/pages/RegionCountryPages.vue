<template>
  <div>
    <div 
      class="card--stats-toggle"
      v-if="tabs.length > 1"
    >
      <tabs-fake
        :children="tabs"
        class="tabs--rounded"
        :defaultSelectedId="tabs[0].id"
        v-on:click:tab="updateDatabaseId"
      ></tabs-fake>
    </div>

    <div 
      class="card--stats-wrapper"
      v-if="hasCoverageStats"
    >
      <stats-coverage
        v-for="stat in activeDatabase.coverage"
        :key="stat._uid"
        v-bind="{
          nationalReportVersion: stat.national_report_version,
          pameKm2: stat.pame_km2,
          pamePercentage: stat.pame_percentage,
          protectedKm2: stat.protected_km2,
          protectedNationalReport: stat.protected_national_report,
          protectedPercentage: stat.protected_percentage,
          textCoverage: stat.text_coverage,
          textNationalReport: stat.text_national_report,
          textPame: stat.text_pame,
          textPameAssessments: stat.text_pame_assessments,
          textProtected: stat.text_protected,
          textTotal: stat.text_total,
          title: stat.title,
          totalKm2: stat.total_km2,
          type: stat.type,
        }"
      />
    </div>

    <stats-message
      v-bind="{
        documents: activeDatabase.message.documents,
        link: activeDatabase.message.link,
        text: activeDatabase.message.text
      }"
    />

    <div class="card--stats-wrapper pdf-break-before">
      <stats-iucn-categories
        v-if="hasIucnCategories"
        v-bind="{
          categories: activeDatabase.iucn.categories,
          chart: activeDatabase.iucn.chart,
          title: activeDatabase.iucn.title
        }"
      />

      <stats-governance
        v-if="hasGovernanceTypes"
        v-bind="{
          governance: activeDatabase.governance.governance,
          chart: activeDatabase.governance.chart,
          title: activeDatabase.governance.title
        }"
      />
    </div>

    <stats-sources
      v-if="hasSources"
      v-bind="{
        count: activeDatabase.sources.count,
        title: activeDatabase.sources.title,
        sourceUpdated: activeDatabase.sources.source_updated,
        sources: activeDatabase.sources.sources
      }"
    />

    <stats-designations
      v-if="hasDesignations"
      v-bind="{
        chart: activeDatabase.designations.chart,
        designations: activeDatabase.designations.designations,
        title: activeDatabase.designations.title,
      }"
    />

    <stats-growth
      v-if="hasGrowth"
      v-bind="{
        chart: activeDatabase.growth.chart,
        smallprint: activeDatabase.growth.smallprint,
        title: activeDatabase.growth.title,
      }"
    />

    <slot name="related_countries" />

    <stats-sites
      v-if="hasSites"
      v-bind="{
        siteDetails: activeDatabase.sites.site_details,
        textViewAll: activeDatabase.sites.text_view_all,
        title: activeDatabase.sites.title,
        viewAll: activeDatabase.sites.view_all 
      }"
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
  name: 'RegionCountryPages',

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
      databaseId: ''
    }
  },

  computed: {
    activeDatabase () {
      return this.data[this.databaseId]
    },
    hasCoverageStats () {
      return 'coverage' in this.activeDatabase && this.activeDatabase.coverage.length > 1
    },
    hasDesignations () {
      return 'designations' in this.activeDatabase && this.activeDatabase.designations.designations.length > 1
    },
    hasGovernanceTypes () {
      return 'governance' in this.activeDatabase
    },
    hasGrowth () {
      return 'growth' in this.activeDatabase
    },
    hasIucnCategories () {
      return 'iucn' in this.activeDatabase
    },
    hasSites () {
      return 'sites' in this.activeDatabase && this.activeDatabase.sites.site_details.length > 1
    },
    hasSources () {
      return 'sources' in this.activeDatabase && this.activeDatabase.sources.sources.length >= 1
    }
  },

  created () {
    this.databaseId = this.tabs[0].id
  },

  methods: {
    updateDatabaseId (id) {
      this.databaseId = id
    }
  }
}
</script>