<template>
  <div v-show="isActive">
    filters
  </div>
</template>

<script>
export default {
  name: 'filters-search',

  props: {
    isActive: {
      required: true,
      type: Boolean
    }
  }
}
</script>