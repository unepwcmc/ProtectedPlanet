<template>
  <div class="card--feault-block sm-sources pdf-break-inside-avoid">
    <h2
      class="card__h2"
      v-text="`${translations.title} (${forPdf ? totalCount : currentSources.length})`"
    />
    <template v-if="forPdf">
      <AttributesParcelSources
        v-for="(sources, sitePid) in sourcesAttributesList"
        :key="sitePid"
        class="card__all-attributes"
        :source-attributes="sources || []"
        :title="subTitleForParcel(sitePid)"
        :translations
      />
    </template>
    <AttributesParcelSources
      v-else
      :source-attributes="currentSources"
      :translations
    />
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import AttributesParcelSources from '@/components/Attributes/ProtectedArea/Source/Attributes.vue'
import useParcelSelection from '@/composables/useParcelSelection'
import type { AttributesProtectedAreaSourcesProps } from '@/types/backend'

type AttributesProtectedAreaSources = AttributesProtectedAreaSourcesProps
const props = defineProps<AttributesProtectedAreaSources>()

const { selectedParcelId } = useParcelSelection()

const currentSources = computed(() => {
  const activeParcelId = selectedParcelId.value ?? Object.keys(props.sourcesAttributesList)[0]
  return activeParcelId ? (props.sourcesAttributesList[activeParcelId] ?? []) : []
})

const totalCount = computed(() =>
  Object.values(props.sourcesAttributesList).reduce((sum, sources) => sum + (sources?.length ?? 0), 0))

function subTitleForParcel(sitePid: string) {
  return props.subTitle ? `${props.subTitle}: ${sitePid}` : sitePid
}
</script>
