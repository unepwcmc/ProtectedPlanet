<template>
  <a
    :id="link.id"
    role="menuitem"
    class="ct-nav-bar-link"
    :class="{ 'ct-nav-bar-link--current': link.is_current_page }"
    :href="link.url"
    v-text="link.label"
  />
</template>

<script setup lang="ts">
import type { NavLink } from '@/types/backend'

defineProps<{ link: NavLink }>()
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-nav-bar-link {
  @apply
  flex
  items-center
  h-full
  p-1
  tw-shared-font-hind-siliguri__light-base-lg-lg
  no-underline;
}

.ct-nav-bar-link--current {
  @apply font-bold;
}
</style>
