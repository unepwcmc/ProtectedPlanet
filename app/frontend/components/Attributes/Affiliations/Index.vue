<template>
  <div class="card--stats-affiliations">
    <h2
      class="card__h2"
      v-text="title"
    />
    <template v-if="forPdf">
      <AttributesAffiliationsList
        v-if="hasAnyAffiliations"
        :affiliationsByParcel
        :subTitle
        :translations
      />
      <p
        v-else
        v-text="translations.no_information"
      />
    </template>
    <template v-else>
      <AttributesAffiliationsList
        v-if="Object.keys(currentAffiliation).length > 0"
        :affiliationsByParcel="currentAffiliation"
        :translations
      />
      <p
        v-else
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

  if (activeParcelId) {
    return {
      [activeParcelId]: affiliationsByParcel.value[activeParcelId] ?? []
    }
  }
  else {
    return { }
  }
})
</script>
