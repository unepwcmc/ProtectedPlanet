<template>
  <div class="popup--download">
    <ul class="popup__ul">
      <li
        v-for="(option, index) in options"
        :key="index"
      >
        <span
          v-if="option.isDownload"
          class="popup__link"
          @click="select(option)"
          v-html="option.title"
        />
        <a
          v-else-if="option.isMap"
          class="popup__link"
          :href="option.url"
          :download="option.title"
          :title="option.title"
          v-html="option.title"
        />
        <a
          v-else
          class="popup__link"
          :href="option.url"
          target="_blank"
          :title="option.title"
          v-html="option.title"
        />
      </li>
    </ul>
  </div>
</template>

<script setup lang="ts">
import type { DownloadOption } from '@/types/backend'

defineProps<{ options: DownloadOption[] }>()
const emit = defineEmits<{ select: [option: DownloadOption] }>()

const select = (option: DownloadOption) => emit('select', option)
</script>
