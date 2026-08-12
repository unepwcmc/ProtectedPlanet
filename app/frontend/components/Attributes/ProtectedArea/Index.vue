<template>
  <div class="ct-attributes-protected-area">
    <h2
      class="ct-attributes-protected-area__title"
      v-text="title"
    />
    <div
      v-if="forPdf"
      class="ct-attributes-protected-area--for-pdf"
    >
      <AttributesProtectedAreaAttributeList
        v-for="(parcelAttributes, index) in attributesList"
        :key="`${index}parcelAttributesList`"
        :forPdf
        :attributes="parcelAttributes.attributes"
      />
    </div>
    <AttributesProtectedAreaAttributeList
      v-else
      :forPdf
      :attributes="currentAttributeSet"
    />
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import AttributesProtectedAreaAttributeList from '@/components/Attributes/ProtectedArea/AttributeList.vue'
import useParcelSelection from '@/composables/useParcelSelection'
import type { AttributesProtectedAreaProps } from '@/types/backend'

type AttributesProtectedArea = AttributesProtectedAreaProps
const props = defineProps<AttributesProtectedArea>()

const { selectedParcelId } = useParcelSelection()

const currentAttributeSet = computed(() => {
  const chosen = props.attributesList.find(set => set.site_pid === selectedParcelId.value)
    ?? props.attributesList[0]
  return chosen?.attributes ?? []
})
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-attributes-protected-area {
  @apply tw-shared-card-stats;
}

.ct-attributes-protected-area--for-pdf {
  @apply tw-shared-card-stats-for-pdf;
}

.ct-attributes-protected-area__title {
  @apply tw-shared-card-title;
}

</style>
