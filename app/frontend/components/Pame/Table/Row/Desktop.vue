<template>
  <tr class="ct-pame-table-row-desktop">
    <td
      class="ct-pame-table-row-desktop__cell"
      v-text="item.name"
    />
    <td
      class="ct-pame-table-row-desktop__cell"
      v-text="item.designation"
    />
    <td class="ct-pame-table-row-desktop__cell">
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
      class="ct-pame-table-row-desktop__cell"
      v-text="item.asmt_id"
    />
    <td
      class="ct-pame-table-row-desktop__cell"
      v-text="countryDisplay"
    />
    <td
      class="ct-pame-table-row-desktop__cell"
      v-text="item.method"
    />
    <td
      class="ct-pame-table-row-desktop__cell"
      v-text="item.asmt_year"
    />
    <td class="ct-pame-table-row-desktop__cell">
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
      class="ct-pame-table-row-desktop__cell ct-pame-table-row-desktop__cell--modal-trigger"
      @click="onOpenModal"
      v-text="item.eff_metaid"
    />
  </tr>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import PameTableRowSiteId from '@/components/Pame/Table/Row/SiteId.vue'
import { joinOrMultiple } from '@/lib/pameTableFormat'
import type { PameEvaluationItem } from '@/types/backend'

const props = defineProps<{
  item: PameEvaluationItem
}>()

const emit = defineEmits<{ openModal: [item: PameEvaluationItem] }>()

const countryDisplay = computed(() => joinOrMultiple(props.item.country))

function onOpenModal() {
  emit('openModal', props.item)
}
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-pame-table-row-desktop {
  @apply
  bg-theme-grey-xlight
  even:bg-white;
}

.ct-pame-table-row-desktop__cell {
  @apply
  py-4
  px-3.5
  border-l-2
  border-dotted
  border-white
  first:border-l-0
  tw-shared-font-hind-siliguri__light-base-grey-black;

  a {
    @apply
    underline
    hover:no-underline;
  }
}

.ct-pame-table-row-desktop__cell--modal-trigger {
  @apply
  tw-shared-font-hind-siliguri__semibold-base-primary
  cursor-pointer
  underline
  hover:no-underline;
}
</style>
