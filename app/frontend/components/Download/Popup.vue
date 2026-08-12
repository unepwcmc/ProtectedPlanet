<template>
  <ul class="ct-download-popup">
    <li
      v-for="(option, index) in options"
      :key="index"
    >
      <span
        v-if="option.isDownload"
        class="ct-download-popup__link"
        @click="select(option)"
        v-html="option.title"
      />
      <a
        v-else-if="option.isMap"
        class="ct-download-popup__link"
        :href="option.url"
        :download="option.title"
        :title="option.title"
        v-html="option.title"
      />
      <a
        v-else
        class="ct-download-popup__link"
        :href="option.url"
        target="_blank"
        :title="option.title"
        v-html="option.title"
      />
    </li>
  </ul>
</template>

<script setup lang="ts">
import type { DownloadOption } from '@/types/backend'

defineProps<{ options: DownloadOption[] }>()
const emit = defineEmits<{ select: [option: DownloadOption] }>()

const select = (option: DownloadOption) => emit('select', option)
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-download-popup {
  @apply
  absolute
  top-[calc(100%+0.5rem)]
  right-0
  z-1
  w-max
  tw-shared-border-radius
  bg-theme-grey-dark
  px-5
  py-2.5
  before:content-['']
  before:absolute
  before:-top-2
  before:right-4
  before:border-x-[1.1875rem]
  before:border-x-transparent
  before:border-b-8
  before:border-b-theme-grey-dark
  list-none
  tw-shared-base-flex-col;
}

.ct-download-popup__link {
  @apply
  py-1.25
  tw-shared-font-hind-siliguri__normal-base-md-lg-white
  no-underline
  cursor-pointer
  hover:underline
  md:text-lg;
}
</style>
