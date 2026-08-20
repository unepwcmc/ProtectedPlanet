<template>
  <div
    class="ct-attributes-affiliations"
    :class="{
      'ct-attributes-affiliations--for-pdf': forPdf
    }"
  >
    <h2
      class="ct-attributes-affiliations__title
      tw-global-pdf-export__break-after-avoid"
      v-text="title"
    />
    <template v-if="forPdf">
      <AttributesAffiliationsList
        v-if="hasAnyAffiliations"
        :forPdf
        :affiliationsByParcel
        :subTitle
        :translations
      />
      <p
        v-else
        class="ct-attributes-affiliations__no-info"
        v-text="translations.no_information"
      />
    </template>
    <template v-else>
      <AttributesAffiliationsList
        v-if="Object.keys(currentAffiliation).length > 0"
        :forPdf
        :affiliationsByParcel="currentAffiliation"
        :translations
      />
      <p
        v-else
        class="ct-attributes-affiliations__no-info"
        v-text="translations.no_information"
      />
    </template>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import AttributesAffiliationsList from '@/components/Attributes/Affiliations/List.vue'
import useParcelSelection from '@/composables/useParcelSelection'
import type { AttributesAffiliationLink, AttributesAffiliationsProps } from '@/types/backend'

type AttributesAffiliations = AttributesAffiliationsProps
const props = defineProps<AttributesAffiliations>()

const { selectedParcelId } = useParcelSelection()

const affiliationsByParcel = computed(() => {
  const byParcel: Record<string, AttributesAffiliationLink[]> = {}
  props.affiliations.forEach((link) => {
    ;(byParcel[link.site_pid] ??= []).push(link)
  })
  return byParcel
})
const hasAnyAffiliations = computed(() => props.affiliations.length > 0)
const currentAffiliation = computed(() => {
  const activeParcelId = selectedParcelId.value ?? Object.keys(affiliationsByParcel.value)[0]
  const affiliations = affiliationsByParcel.value[activeParcelId] ?? []
  if (activeParcelId && affiliations.length > 0) {
    return {
      [activeParcelId]: affiliations
    }
  }
  else {
    return { }
  }
})
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-attributes-affiliations {
  @apply tw-shared-card-stats;
}

.ct-attributes-affiliations--for-pdf{
  @apply tw-shared-card-stats-for-pdf;
}

.ct-attributes-affiliations__title {
  @apply tw-shared-card-title;
}

.ct-attributes-affiliations__no-info {
  @apply tw-shared-card-no-info-text;
}
</style>
