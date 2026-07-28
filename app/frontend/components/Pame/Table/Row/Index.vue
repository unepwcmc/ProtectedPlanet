<template>
  <tr class="table__row">
    <td
      class="table__cell"
      v-text="item.name"
    />
    <td
      class="table__cell"
      v-text="item.designation"
    />
    <td class="table__cell">
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
    </td>
    <td
      class="table__cell"
      v-text="item.asmt_id"
    />
    <td
      class="table__cell"
      v-text="countryDisplay"
    />
    <td
      class="table__cell"
      v-text="item.method"
    />
    <td
      class="table__cell"
      v-text="item.asmt_year"
    />
    <td class="table__cell">
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
    </td>
    <td
      class="table__cell table__cell-modal-trigger"
      @click="onOpenModal"
      v-text="item.eff_metaid"
    />
  </tr>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import PameTableRowSiteId from '@/components/Pame/Table/Row/SiteId.vue'
import { joinOrMultiple } from '@/lib/pameTableFormat'
import { usePameStore } from '@/stores/usePameStore'
import type { PameEvaluationItem } from '@/types/backend'

const props = defineProps<{
  item: PameEvaluationItem
}>()

const pameStore = usePameStore()

const countryDisplay = computed(() => joinOrMultiple(props.item.country))

function onOpenModal() {
  pameStore.openModal(props.item)
}
</script>
