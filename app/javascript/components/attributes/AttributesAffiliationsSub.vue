<template>
  <div>
    <h3 v-if="subTitle" class="card__h3">{{ subTitle }}</h3>
    <ul class="card__logos">
      <AttributesAffiliation
        v-for="(link, index) in links"
        :key="index"
        :link="link"
        :translations="translations"
      />
    </ul>
  </div>
</template>

<script>
import AttributesAffiliation from './AttributesAffiliation.vue'

export default {
  name: 'AttributesAffiliationsSub',

  components: {
    AttributesAffiliation
  },

  props: {
    // List of affiliation objects for one parcel/section
    links: {
      type: Array,
      required: true,
      default: () => []
    },
    subTitle: {
      type: String,
      default: undefined
    },
    translations: {
      type: Object,
      required: true,
      default: () => ({})
    }
  }
}
</script>
