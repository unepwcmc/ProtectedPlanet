<template>
  <tr class="ct-pame-table-row-mobile">
    <td
      class="ct-pame-table-row-mobile__items"
      :class="{ 'ct-pame-table-row-mobile__items--last': isLast }"
    >
      <p class="ct-pame-table-row-mobile__item">
        <span
          class="ct-pame-table-row-mobile__item-label"
          v-text="`${attributes[0].title}:`"
        />
        <span
          class="ct-pame-table-row-mobile__item-value"
          v-text="item.name"
        />
      </p>
      <p class="ct-pame-table-row-mobile__item">
        <span
          class="ct-pame-table-row-mobile__item-label"
          v-text="`${attributes[1].title}:`"
        />
        <span
          class="ct-pame-table-row-mobile__item-value"
          v-text="item.designation"
        />
      </p>
      <p class="ct-pame-table-row-mobile__item">
        <span
          class="ct-pame-table-row-mobile__item-label"
          v-text="`${attributes[2].title}:`"
        />
        <span class="ct-pame-table-row-mobile__item-value">
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
      <p class="ct-pame-table-row-mobile__item">
        <span
          class="ct-pame-table-row-mobile__item-label"
          v-text="`${attributes[3].title}:`"
        />
        <span
          class="ct-pame-table-row-mobile__item-value"
          v-text="item.asmt_id"
        />
      </p>
      <p class="ct-pame-table-row-mobile__item">
        <span
          class="ct-pame-table-row-mobile__item-label"
          v-text="`${attributes[4].title}:`"
        />
        <span
          class="ct-pame-table-row-mobile__item-value"
          v-text="countryDisplay"
        />
      </p>
      <p class="ct-pame-table-row-mobile__item">
        <span
          class="ct-pame-table-row-mobile__item-label"
          v-text="`${attributes[5].title}:`"
        />
        <span
          class="ct-pame-table-row-mobile__item-value"
          v-text="item.method"
        />
      </p>
      <p class="ct-pame-table-row-mobile__item">
        <span
          class="ct-pame-table-row-mobile__item-label"
          v-text="`${attributes[6].title}:`"
        />
        <span
          class="ct-pame-table-row-mobile__item-value"
          v-text="item.asmt_year"
        />
      </p>
      <p class="ct-pame-table-row-mobile__item">
        <span
          class="ct-pame-table-row-mobile__item-label"
          v-text="`${attributes[7].title}:`"
        />
        <span class="ct-pame-table-row-mobile__item-value">
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
      <p class="ct-pame-table-row-mobile__item--no-flex">
        <button
          class="ct-pame-table-row-mobile__item-label
          ct-pame-table-row-mobile__item--modal-trigger"
          type="button"
          @click="onOpenModal"
          v-text="`${attributes[8].title}: ${item.eff_metaid}`"
        />
      </p>
    </td>
  </tr>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import PameTableRowSiteId from '@/components/Pame/Table/Row/SiteId.vue'
import { joinOrMultiple } from '@/lib/pameTableFormat'
import type { PameEvaluationItem, PameTableAttribute } from '@/types/backend'

const props = withDefaults(defineProps<{
  item: PameEvaluationItem
  attributes: PameTableAttribute[]
  isLast?: boolean
}>(), {
  isLast: false
})

const emit = defineEmits<{ openModal: [item: PameEvaluationItem] }>()

const countryDisplay = computed(() => joinOrMultiple(props.item.country))

function onOpenModal() {
  emit('openModal', props.item)
}
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-pame-table-row-mobile__items {
  @apply
  bg-theme-grey-xlight
  py-1
  px-3.5
  border-b-12
  border-white
  tw-shared-base-flex-col;
}

.ct-pame-table-row-mobile__items--last {
  @apply border-b-0;
}

.ct-pame-table-row-mobile__item {
  @apply
  py-3
  tw-shared-base-flex-gap-2;
}

.ct-pame-table-row-mobile__item--no-flex {
  @apply
  py-3;
}

.ct-pame-table-row-mobile__item-label {
  @apply tw-shared-font-hind-siliguri__semibold-base-grey-black;
}

.ct-pame-table-row-mobile__item-value {
  @apply tw-shared-font-hind-siliguri__light-base-grey-black;
}

.ct-pame-table-row-mobile__item--modal-trigger {
  @apply
  cursor-pointer
  tw-shared-font-hind-siliguri__semibold-base-primary
  underline
  hover:no-underline;
}
</style>
