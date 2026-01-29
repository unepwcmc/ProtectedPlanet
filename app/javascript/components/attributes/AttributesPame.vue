<template>
  <div>
    <h3 class="card__h3" v-if="title">{{ title }}</h3>
    <ul class="list--stripes" v-if="Object.keys(pameAttributes).length > 0">
      <li
        v-for="(years, methodology) in pameAttributes"
        :key="methodology"
        class="list__li"
      >
        <span class="list__title">{{ methodology }}</span>
        <span class="list__value">{{ years.join(', ') }}</span>
      </li>
    </ul>
    <p v-else>
      {{ translations.no_information }}
    </p>
  </div>
</template>

<script>
export default {
  name: 'AttributesPame',

  props: {
    // { method => [years...] } - a single parcel's pame Attributes
    pameAttributes: {
      type: Object,
      required: true,
      default: () => ({})
    },
    title: {
      type: String,
      default: undefined
    },
    translations: {
      type: Object,
      required: true,
      default: () => ({
        no_information: 'No information available'
      })
    }
  }
}
</script>

