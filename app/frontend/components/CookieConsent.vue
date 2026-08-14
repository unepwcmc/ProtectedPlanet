<template>
  <div
    v-if="visible"
    class="ct-cookie-consent"
  >
    <div class="ct-cookie-consent__container">
      <p
        class="ct-cookie-consent__description"
        v-html="props.description"
      />
      <div class="ct-cookie-consent__decisions">
        <button
          class="ct-cookie-consent__button ct-cookie-consent__button--accept"
          @click.prevent="accept"
        >
          {{ props.accept }}
        </button>
        <button
          class="ct-cookie-consent__button ct-cookie-consent__button--reject"
          @click.prevent="reject"
        >
          {{ props.reject }}
        </button>
      </div>
    </div>
    <div class="ct-cookie-consent__overlay" />
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { getConsent } from '@/lib/cookieConsent'
import useAnalytics from '@/composables/useAnalytics'
import useFreezeBackground from '@/composables/useFreezeBackground'
import type { CookieConsentProps } from '@/types/backend'

const props = defineProps<CookieConsentProps>()

const { acceptAnalytics, rejectAnalytics } = useAnalytics()

const visible = ref(getConsent() === null)

// Banner sits over an overlay, so the page behind it shouldn't scroll while it's up.
useFreezeBackground(visible)

function accept() {
  acceptAnalytics()
  visible.value = false
}

function reject() {
  rejectAnalytics()
  visible.value = false
}
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-cookie-consent {
  @apply
  lg:flex
  lg:items-center;
}

.ct-cookie-consent__container {
  @apply
  fixed
  bottom-0
  z-20
  w-full
  tw-shared-base-flex-col-md-row-gap-3
  lg:items-center
  lg:justify-between
  bg-theme-primary
  p-3
  md:px-6
  md:py-9;
}

.ct-cookie-consent__description {
  @apply tw-shared-font-hind-siliguri__normal-lg-white;

  a {
    @apply
    underline
    hover:no-underline;
  }
}

.ct-cookie-consent__decisions {
  @apply
  flex
  items-center
  text-white;
}

.ct-cookie-consent__button {
  @apply
  bg-transparent
  border-none
  flex
  items-center
  gap-3
  p-3
  tw-shared-font-hind-siliguri__normal-lg-white
  uppercase;
}

.ct-cookie-consent__button--accept {
  @apply
  border-2
  border-solid
  border-white
  font-semibold;
}

.ct-cookie-consent__overlay {
  @apply
  fixed
  inset-0
  z-10
  bg-black/75;
}
</style>
