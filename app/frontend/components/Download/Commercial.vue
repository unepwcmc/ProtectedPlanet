<template>
  <div class="ct-download-commercial">
    <div class="ct-download-commercial__dialog">
      <button
        class="ct-download-commercial__close"
        @click="close"
      >
        <IconClose class="ct-download-commercial__close-icon" />
      </button>
      <h4
        class="ct-download-commercial__title"
        v-text="text.title"
      />
      <div class="ct-download-commercial__links">
        <div class="ct-download-commercial__link">
          <span
            class="ct-download-commercial__link-title"
            v-text="text.commercialTitle"
          />
          <span
            class="ct-download-commercial__link-text"
            v-html="text.commercialText"
          />
        </div>

        <span class="ct-download-commercial__divider" />

        <div class="ct-download-commercial__link">
          <span
            class="ct-download-commercial__link-title"
            v-text="text.nonCommercialTitle"
          />
          <span
            class="ct-download-commercial__link-text"
            v-text="text.nonCommercialText"
          />
          <button
            class="ct-download-commercial__link-button"
            @click="selectNonCommercial"
          >
            <span
              class="ct-download-commercial__link-button-text"
              v-text="text.nonCommercialButton"
            />
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import IconClose from '@/components/Icon/Close.vue'
import type { DownloadProps } from '@/types/backend'

defineProps<{
  text: DownloadProps['textCommercial']
}>()

const emit = defineEmits<{ close: [], nonCommercial: [] }>()

const close = () => emit('close')
const selectNonCommercial = () => emit('nonCommercial')
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-download-commercial {
  @apply
  fixed
  inset-0
  z-2
  bg-black/60;
}

.ct-download-commercial__dialog {
  @apply
  fixed
  top-1/2
  left-1/2
  z-3
  w-9/10
  -translate-x-1/2
  -translate-y-1/2
  tw-shared-border-radius
  bg-white
  px-6.5
  pt-8.5
  pb-3.5
  md:w-187
  md:px-9.5
  md:pt-8
  md:pb-15
  tw-shared-base-flex-col-gap-6;
}

.ct-download-commercial__close {
  @apply
  tw-shared-button-basic
  absolute
  top-4.5
  right-4.5;
}

.ct-download-commercial__close-icon {
  @apply
  size-5
  text-theme-grey-black;
}

.ct-download-commercial__title {
  @apply
  tw-shared-font-hind-siliguri__bold-xl-grey-black
  text-center;
}

.ct-download-commercial__links {
  @apply
  tw-shared-base-flex-col-md-row-gap-3
  justify-start
  md:justify-between;
}

.ct-download-commercial__link {
  @apply
  w-full
  tw-shared-border-radius
  py-5
  items-center
  md:py-0
  md:px-4
  tw-shared-base-flex-col-gap-3;
}

.ct-download-commercial__link-title {
  @apply
  tw-shared-font-hind-siliguri__bold-xl-grey-black
  text-center;
}

.ct-download-commercial__link-text {
  @apply tw-shared-font-hind-siliguri__light-base-grey-black;
}

.ct-download-commercial__divider {
  @apply
  bg-theme-grey-light
  h-px
  w-full
  md:h-37.5
  md:w-px;
}

.ct-download-commercial__link-button {
  @apply
  tw-shared-button--theme-purple
  md:w-auto;
}
</style>
