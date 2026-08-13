<template>
  <a
    class="ct-card-item"
    :class="[
      hasSecondaryLine && 'ct-card-item--has-secondary-line',
      modifier && `ct-card-item--${modifier}`,
    ]"
    :href="url"
    :title="linkTitle"
  >
    <div
      v-if="image"
      class="ct-card-item__image"
      :style="{ backgroundImage: `url(${image})` }"
    />
    <div
      v-else
      class="ct-card-item__image"
    >
      <IconPlaceholderImage class="ct-card-item__placeholder-icon" />
    </div>
    <div class="ct-card-item__content">
      <h3
        v-if="titleIsHtml"
        class="ct-card-item__title"
        v-html="title"
      />
      <h3
        v-else
        class="ct-card-item__title"
        v-text="title"
      />
      <span
        v-if="hasSecondaryLine && secondaryText"
        class="ct-card-item__secondary-text"
        v-html="secondaryText"
      />
    </div>
  </a>
</template>

<script setup lang="ts">
import IconPlaceholderImage from '@/components/Icon/PlaceholderImage.vue'

withDefaults(defineProps<{
  hasSecondaryLine?: boolean
  image?: string
  linkTitle?: string
  modifier?: string
  secondaryText?: string
  title: string
  titleIsHtml?: boolean
  url: string
}>(), {
  hasSecondaryLine: false,
  image: undefined,
  modifier: undefined,
  secondaryText: undefined,
  titleIsHtml: false
})
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-card-item {
  @apply
  tw-shared-shadow-grey-light
  tw-shared-base-flex-col-gap-3
  w-full
  md:w-[48%]
  lg:w-[31.5%]
  h-auto
  md:h-90
  min-h-70
  bg-white
  px-4.5
  pt-4.5
  pb-4
  no-underline
  hover:no-underline;
}

.ct-card-item--has-secondary-line {
  @apply
  gap-3
  mb-7.5;
}

.ct-card-item__image {
  @apply
  tw-shared-image-placeholder
  h-38.75;
}

.ct-card-item__placeholder-icon {
  @apply
  w-[30%]
  text-white;
}

.ct-card-item__content {
  @apply tw-shared-base-flex-col-gap-1;
}

.ct-card-item__title {
  @apply tw-shared-font-hind-siliguri__semibold-xl-grey-black;
}

.ct-card-item__secondary-text {
  @apply tw-shared-font-hind-siliguri__light-lg-grey-black;
}
</style>
