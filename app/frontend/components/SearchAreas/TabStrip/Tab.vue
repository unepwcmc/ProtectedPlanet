<template>
  <li
    :class="['tab__trigger', { active: isActive }]"
    @click="click"
    v-text="title"
  />
</template>

<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{
  id: string
  selectedId: string
  title: string
}>()

const emit = defineEmits<{ 'click:tab': [id: string] }>()

const isActive = computed(() => props.id === props.selectedId)

function click() {
  emit('click:tab', props.id)
}
</script>
