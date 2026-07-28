<template>
  <div class="card--attributes-pame">
    <h2
      class="card__h2"
      v-text="title"
    />
    <template v-if="forPdf">
      <AttributesPame
        v-for="(pameAttributes, sitePid) in pamesAttributesList"
        :key="sitePid"
        class="card__all-attributes"
        :pameAttributes
        :title="subTitle ? `${subTitle}: ${sitePid}` : undefined"
        :translations
      />
    </template>
    <AttributesPame
      v-else
      :pameAttributes="currentPameAttributes"
      :translations
    />
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import AttributesPame from '@/components/Attributes/Pame/Pame.vue'
import { useParcelSelection } from '@/composables/useParcelSelection'
import type { AttributesPameListProps } from '@/types/backend'

type AttributesPameList = AttributesPameListProps
const props = defineProps<AttributesPameList>()

const { selectedParcelId } = useParcelSelection()

const currentPameAttributes = computed(() => {
  const activeParcelId = selectedParcelId.value ?? Object.keys(props.pamesAttributesList)[0]
  return activeParcelId ? (props.pamesAttributesList[activeParcelId] ?? {}) : {}
})
</script>
