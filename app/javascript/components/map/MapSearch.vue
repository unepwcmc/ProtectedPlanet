<template>
  <div
    v-show="isActive"
    class="map--search"
  >
    <div class="map__map">
      <h1>map component here</h1>
    </div>
  </div>
</template>

<script>
export default {
  name: 'MapSearch',

  props: {
    isActive: {
      required: true,
      type: Boolean
    }
  },
}
</script>
