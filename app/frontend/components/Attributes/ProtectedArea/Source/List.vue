<template>
  <div class="ct-attributes-protected-area-sources">
    <h2
      class="ct-attributes-protected-area-sources__title"
      v-text="`${translations.title} (${forPdf ? totalCount : currentSources.length})`"
    />
    <div
      v-if="forPdf"
      class="ct-attributes-protected-area-sources--pdf"
    >
      <AttributesParcelSources
        v-for="(sources, sitePid) in sourcesAttributesList"
        :key="sitePid"
        :forPdf
        :sourceAttributes="sources || []"
        :title="subTitleForParcel(sitePid)"
        :translations
      />
    </div>
    <AttributesParcelSources
      v-else
      :forPdf
      :sourceAttributes="currentSources"
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

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-attributes-protected-area-sources {
  @apply tw-shared-card-stats;
}

.ct-attributes-protected-area-sources--pdf {
  @apply tw-shared-card-stats-for-pdf;
}

.ct-attributes-protected-area-sources__title {
  @apply tw-shared-card-title;
}
</style>
