<template>
  <tr class="table__list">
    <td
      class="table__list-items"
      :class="{ 'table__list-items--last': isLast }"
    >
      <p class="table__list-item table__list-item--name">
        <span
          class="table__list-item-label"
          v-text="`${attributes[0].title}:`"
        />
        <span
          class="table__list-item-value"
          v-text="item.name"
        />
      </p>
      <p class="table__list-item table__list-item--designation">
        <span
          class="table__list-item-label"
          v-text="`${attributes[1].title}:`"
        />
        <span
          class="table__list-item-value"
          v-text="item.designation"
        />
      </p>
      <p class="table__list-item able__list-item--site-id">
        <span
          class="table__list-item-label"
          v-text="`${attributes[2].title}:`"
        />
        <span class="table__list-item-value">
          <a
            v-if="item.site_id"
            :href="item.pa_site_url"
            title="View protected area on Protected Planet"
            target="_blank"
          >
            <PameTableRowSiteId
              :siteId="item.site_id"
              :sitePid="item.site_pid"
            />
          </a>
          <PameTableRowSiteId
            v-else
            :siteId="item.site_id"
            :sitePid="item.site_pid"
          />
        </span>
      </p>
      <p class="table__list-item table__list-item--assessment-id">
        <span
          class="table__list-item-label"
          v-text="`${attributes[3].title}:`"
        />
        <span
          class="table__list-item-value"
          v-text="item.asmt_id"
        />
      </p>
      <p class="table__list-item table__list-item--country">
        <span
          class="table__list-item-label"
          v-text="`${attributes[4].title}:`"
        />
        <span
          class="table__list-item-value"
          v-text="countryDisplay"
        />
      </p>
      <p class="table__list-item table__list-item--method">
        <span
          class="table__list-item-label"
          v-text="`${attributes[5].title}:`"
        />
        <span
          class="table__list-item-value"
          v-text="item.method"
        />
      </p>
      <p class="table__list-item table__list-item--year-of-assessment">
        <span
          class="table__list-item-label"
          v-text="`${attributes[6].title}:`"
        />
        <span
          class="table__list-item-value"
          v-text="item.asmt_year"
        />
      </p>
      <p class="table__list-item table__list-item--link-to-assessment">
        <span
          class="table__list-item-label"
          v-text="`${attributes[7].title}:`"
        />
        <span class="table__list-item-value">
          <a
            v-if="item.asmt_url.includes('http')"
            :href="item.asmt_url"
            title="View assessment"
            target="_blank"
          >
            Link
          </a>
          <span
            v-else
            v-text="item.asmt_url"
          />
        </span>
      </p>
      <p
        class="table__list-item table__list-item--metadata-id table__cell-modal-trigger"
        @click="onOpenModal"
      >
        <span
          class="table__list-item-label"
          v-text="`${attributes[8].title}:`"
        />
        <span
          class="table__list-item-value"
          v-text="item.eff_metaid"
        />
      </p>
    </td>
  </tr>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import PameTableRowSiteId from '@/components/Pame/Table/Row/SiteId.vue'
import { joinOrMultiple } from '@/lib/pameTableFormat'
import { usePameStore } from '@/stores/usePameStore'
import type { PameEvaluationItem, PameTableAttribute } from '@/types/backend'

const props = withDefaults(defineProps<{
  item: PameEvaluationItem
  attributes: PameTableAttribute[]
  isLast?: boolean
}>(), {
  isLast: false
})

const pameStore = usePameStore()

const countryDisplay = computed(() => joinOrMultiple(props.item.country))

function onOpenModal() {
  pameStore.openModal(props.item)
}
</script>
