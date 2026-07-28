<template>
  <ul class="card__all-attributes">
    <li
      v-for="(links, sitePid) in affiliationsByParcel"
      :key="sitePid"
    >
      <h3
        v-if="subTitle"
        class="card__h3"
        v-text="subTitleMerge(sitePid)"
      />
      <ul class="card__logos">
        <AttributesAffiliationsAffiliation
          v-for="(link, index) in links"
          :key="index"
          :link
          :translations
        />
      </ul>
    </li>
  </ul>
</template>

<script setup lang="ts">
import type { AttributesAffiliationLink, AttributesAffiliationsTranslations } from '@/types/backend'
import AttributesAffiliationsAffiliation from '@/components/Attributes/Affiliations/Affiliation.vue'

const props = defineProps<{
  affiliationsByParcel: Record<string, AttributesAffiliationLink[]>
  subTitle?: string
  translations: AttributesAffiliationsTranslations
}>()

function subTitleMerge(sitePid: string) {
  return props.subTitle ? `${props.subTitle}: ${sitePid}` : undefined
}
</script>
