<template>
  <div class="card--attributes-pa-and-parcels">
    <h2
      class="card__h2"
      v-text="title"
    />
    <div
      v-if="forPdf"
      class="card__all-attributes"
    >
      <AttributesProtectedAreaAttributeList
        v-for="(parcelAttributes, index) in attributesList"
        :key="`${index}parcelAttributesList`"
        :attributes="parcelAttributes.attributes"
        :show-site-pid="true"
      />
    </div>
    <AttributesProtectedAreaAttributeList
      v-else
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
