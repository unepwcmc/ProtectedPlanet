<template>
  <a
    :id="link.id"
    role="menuitem"
    class="nav__a"
    :class="{ 'is-current-page': link.is_current_page }"
    :href="link.url"
    v-text="link.label"
  />
</template>

<script setup lang="ts">
import type { NavLink } from '@/types/backend'

defineProps<{ link: NavLink }>()
</script>
