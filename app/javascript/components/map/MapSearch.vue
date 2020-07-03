<template>
  <div class="map--search" v-show="isActive">
    <div class="map__map">
      <h1>map here</h1>
    </div>
  </div>
</template>

<script>
export default {
  name: 'map-search',

  props: {
    isActive: {
      required: true,
      type: Boolean
    }
  },
}
</script>
