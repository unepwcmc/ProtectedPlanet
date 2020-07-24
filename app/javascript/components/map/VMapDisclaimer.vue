<template>
  <div
    v-if="disclaimer"
    class="v-map-disclaimer"
  >
    <div class="v-map-disclaimer__heading">
      {{ disclaimer.heading }}
    </div>
    <div
      class="v-map-disclaimer__body"
      v-html="disclaimer.body"
    />
  </div>
</template>

<script>
export default {
  props: {
    disclaimer: {
      type: Object,
      required: true,
      validator: type => (
        type.hasOwnProperty('heading') &&
        typeof type.heading === 'string' &&
        type.hasOwnProperty('body') &&
        typeof type.heading === 'string'
      )
    },
  }
}
</script>