<template>
  <div>
    <div
      v-if="tabs.length > 1"
      class="card--stats-toggle"
    >
      <SearchAreasTabStrip
        class="tabs--rounded"
        :children="tabs"
        :gaId="gaId"
        @click:tab="onSelectDatabase"
      />
    </div>
    <div
      v-if="hasCoverageStats"
      class="card--stats-wrapper"
    >
      <StatsCoverage
        v-for="(stat, i) in coverageProps"
        :key="i"
        v-bind="stat"
      />
    </div>
    <StatsMessage v-bind="activeDatabase.message" />
    <div class="card--stats-wrapper pdf-break-before">
      <StatsIucnCategories
        v-if="activeDatabase.iucn"
        v-bind="iucnProps"
      />

      <StatsGovernance
        v-if="activeDatabase.governance"
        v-bind="governanceProps"
      />
    </div>
    <StatsSources
      v-if="hasSources"
      v-bind="sourcesProps"
    />
    <StatsDesignations
      v-if="hasDesignations"
      v-bind="activeDatabase.designations!"
    />
    <div
      v-if="relatedCountriesHtml"
      v-html="relatedCountriesHtml"
    />
    <StatsSites
      v-if="hasSites"
      v-bind="sitesProps"
    />
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import SearchAreasTabStrip from '@/components/SearchAreas/TabStrip/Index.vue'
import StatsCoverage from '@/components/Stats/Coverage.vue'
import StatsDesignations from '@/components/Stats/Designations.vue'
import StatsGovernance from '@/components/Stats/Governance.vue'
import StatsIucnCategories from '@/components/Stats/IucnCategories.vue'
import StatsMessage from '@/components/Stats/Message.vue'
import StatsSites from '@/components/Stats/Sites.vue'
import StatsSources from '@/components/Stats/Sources.vue'
import type {
  RegionCountryPagesProps,
  StatsCoverageDatum,
  StatsCoverageProps,
  StatsGovernanceData,
  StatsGovernanceProps,
  StatsIucnCategoriesData,
  StatsIucnCategoriesProps,
  StatsSitesData,
  StatsSitesProps,
  StatsSourcesData,
  StatsSourcesProps
} from '@/types/backend'

type RegionCountryPages = RegionCountryPagesProps
const props = defineProps<RegionCountryPages>()

const selectedDatabaseId = ref(props.tabs[0].id)

const activeDatabase = computed(() => props.data[selectedDatabaseId.value])

const hasCoverageStats = computed(() =>
  (activeDatabase.value.coverage?.length ?? 0) > 1)

const hasDesignations = computed(() =>
  (activeDatabase.value.designations?.designations.length ?? 0) > 1)

const hasSources = computed(() =>
  (activeDatabase.value.sources?.sources.length ?? 0) >= 1)

const hasSites = computed(() =>
  (activeDatabase.value.sites?.site_details.length ?? 0) > 1)

const coverageProps = computed(() => (activeDatabase.value.coverage ?? []).map(mapCoverage))

// Non-null: only read from the template when `hasSources`/`hasSites` (guarding
// the same `v-if`) is true, so `activeDatabase.value.sources`/`.sites` is
// always present at that point — the `v-if` short-circuits the vnode's prop
// evaluation, so these are never actually read otherwise.
const sourcesProps = computed(() => mapSources(activeDatabase.value.sources!))

const sitesProps = computed(() => mapSites(activeDatabase.value.sites!))

const iucnProps = computed(() => mapIucnCategories(activeDatabase.value.iucn!))

const governanceProps = computed(() => mapGovernance(activeDatabase.value.governance!))

function onSelectDatabase(id: string) {
  selectedDatabaseId.value = id
}

function mapCoverage(datum: StatsCoverageDatum): StatsCoverageProps {
  return {
    nationalReportVersion: datum.national_report_version,
    pameKm2: datum.pame_km2,
    pamePercentage: datum.pame_percentage,
    protectedKm2: datum.protected_km2,
    protectedNationalReport: datum.protected_national_report,
    protectedPercentage: datum.protected_percentage,
    textCoverage: datum.text_coverage,
    textNationalReport: datum.text_national_report,
    textPame: datum.text_pame,
    textPameAssessments: datum.text_pame_assessments,
    textProtected: datum.text_protected,
    textTotal: datum.text_total,
    title: datum.title,
    totalKm2: datum.total_km2,
    type: datum.type
  }
}

function mapSources(data: StatsSourcesData): StatsSourcesProps {
  return {
    count: data.count,
    sourceUpdated: data.source_updated,
    sources: data.sources,
    title: data.title
  }
}

function mapSites(data: StatsSitesData): StatsSitesProps {
  return {
    siteDetails: data.site_details,
    textViewAll: data.text_view_all,
    title: data.title,
    viewAll: data.view_all
  }
}

// TabPresenter#iucn/#governance also carry a `country` field the component
// doesn't use — picked out here rather than `v-bind`-spreading the raw object,
// so it doesn't fall through onto the DOM as a stray attribute.
function mapIucnCategories(data: StatsIucnCategoriesData): StatsIucnCategoriesProps {
  return { categories: data.categories, chart: data.chart, title: data.title }
}

function mapGovernance(data: StatsGovernanceData): StatsGovernanceProps {
  return { governance: data.governance, chart: data.chart, title: data.title }
}
</script>
