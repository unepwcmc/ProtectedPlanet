<template>
  <div class="v-map-header">
    <span
      class="v-map-header__title"
      v-text="title"
    />
    <div
      v-if="closeable"
      class="v-map-header__close"
      :class="{ closed: !filtersShown }"
      @click="emit('toggle')"
    />
  </div>
</template>

<script setup lang="ts">

withDefaults(defineProps<{
  title: string
  closeable?: boolean
  filtersShown?: boolean
}>(), {
  closeable: false,
  filtersShown: true
})

const emit = defineEmits<{ toggle: [] }>()
</script>
