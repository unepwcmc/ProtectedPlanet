<template>
  <div
    class="ct-attributes-pame-list
    tw-global-pdf-export__break-inside-avoid"
    :class="{
      'ct-attributes-pame-list--pdf': forPdf
    }"
  >
    <h2
      class="ct-attributes-pame-list__title
      tw-global-pdf-export__break-after-avoid"
      v-text="title"
    />
    <template v-if="forPdf">
      <AttributesPamePame
        v-for="(pameAttributes, sitePid) in pamesAttributesList"
        :key="sitePid"
        :pameAttributes
        :forPdf
        :title="subTitle ? `${subTitle}: ${sitePid}` : undefined"
        :translations
      />
    </template>
    <AttributesPamePame
      v-else
      :forPdf
      :pameAttributes="currentPameAttributes"
      :translations
    />
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import AttributesPamePame from '@/components/Attributes/Pame/Pame.vue'
import useParcelSelection from '@/composables/useParcelSelection'
import type { AttributesPameListProps } from '@/types/backend'

type AttributesPameList = AttributesPameListProps
const props = defineProps<AttributesPameList>()

const { selectedParcelId } = useParcelSelection()

const currentPameAttributes = computed(() => {
  const activeParcelId = selectedParcelId.value ?? Object.keys(props.pamesAttributesList)[0]
  return activeParcelId ? (props.pamesAttributesList[activeParcelId] ?? {}) : {}
})
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-attributes-pame-list {
  @apply tw-shared-card-stats;
}

.ct-attributes-pame-list--pdf {
  @apply tw-shared-base-flex-col-gap-6;
}

.ct-attributes-pame-list__title {
  @apply tw-shared-card-title;
}
</style>
