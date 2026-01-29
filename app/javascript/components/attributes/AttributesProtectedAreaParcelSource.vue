<template>
  <div class="card--stats-source">
    <h2 class="card__h2" v-if="title" v-text="title"/>
    <div class="card__content flex">
      <ol class="list--underline-sources">
        <li class="list__li" v-for="(source, index) in sourceAttributes" :key="`${index}sourceAttributes`">
          <span class="list__title">{{ source.title }}</span>
          <span class="list__date">{{ translations.updated }}: {{ source.date_updated }}</span>
          <span class="list__party">{{ source.resp_party }}</span>
        </li>
      </ol>
    </div>


  </div>
</template>

<script>
export default {
  name: "AttributesProtectedAreaParcel",
  props: {
    title: {
      type: String,
      required: false,
      default: undefined
    },
    sourceAttributes: {
      /**
       * 
       *     {
       *      title: string
       *      date_updated: string
       *      resp_party: string
       *    }[]
       */
      type: Array,
      required: true,
      default: () => ({})
    },
    translations: {
      type: Object,
      required: true,
      default: () => ({})
    }
  }
}
</script>

