<template>
  <ul
    class="ct-attributes-affiliations-list"
    :class="{
      'ct-attributes-affiliations-list--for-pdf': forPdf
    }"
  >
    <li
      v-for="(links, sitePid) in affiliationsByParcel"
      :key="sitePid"
      class="ct-attributes-affiliations-list__item"
    >
      <h3
        v-if="subTitle"
        class="ct-attributes-affiliations-list__subtitle"
        v-text="subTitleMerge(sitePid)"
      />
      <ul class="ct-attributes-affiliations-list__affiliations">
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
  forPdf: boolean
}>()

function subTitleMerge(sitePid: string) {
  return props.subTitle ? `${props.subTitle}: ${sitePid}` : undefined
}
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-attributes-affiliations-list {
  @apply tw-shared-base-flex-col-gap-6;
}

.ct-attributes-affiliations-list--for-pdf {
  @apply tw-shared-card-stats-for-pdf;
}

.ct-attributes-affiliations-list__item {
  @apply tw-shared-base-flex-col-gap-3;
}

.ct-attributes-affiliations-list__subtitle {
  @apply tw-shared-card-sub-title;
}

.ct-attributes-affiliations-list__affiliations {
  @apply tw-shared-base-flex-col-gap-3;
}
</style>
