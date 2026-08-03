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
import { useAnalytics } from '@/composables/useAnalytics'
import { useFreezeBackground } from '@/composables/useFreezeBackground'
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
@reference "tailwindcss";

.ct-cookie-consent {
  @apply lg:flex lg:items-center;
}

.ct-cookie-consent__container {
  @apply fixed bottom-0 z-50 flex w-full flex-col gap-1 bg-theme-primary p-3 md:p-6 lg:flex-row lg:items-center lg:justify-between lg:gap-4;
}

.ct-cookie-consent__description {
  @apply text-base font-bold leading-[1.4] text-white;

  a {
    @apply underline;
  }
}

.ct-cookie-consent__decisions {
  @apply flex items-center text-white;
}

.ct-cookie-consent__button {
  @apply
  bg-transparent
  border-none
  flex
  items-center
  gap-3
  p-3
  text-sm
  font-bold
  uppercase
  leading-none
  text-white;
}

.ct-cookie-consent__button--accept {
  @apply
  border
  border-solid
  border-white;
}

.ct-cookie-consent__overlay {
  @apply
  fixed
  inset-0
  z-40
  bg-black/75;
}
</style>
