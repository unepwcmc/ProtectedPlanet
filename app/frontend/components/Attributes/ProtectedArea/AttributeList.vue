<template>
  <ul
    v-if="attributes.length > 0"
    class="list--stripes"
  >
    <template
      v-for="(attribute, index) in attributes"
      :key="`${index}parcelattribute`"
    >
      <li
        v-if="showSitePid || !attribute.is_site_pid"
        class="list__li"
      >
        <span
          class="list__title"
          v-text="attribute.title"
        />
        <!-- Trusted server-rendered value (ProtectedAreaPresenter), not user input. -->
        <span
          class="list__value"
          v-html="attribute.value"
        />
      </li>
    </template>
  </ul>
</template>

<script setup lang="ts">
import type { AttributesAttributeItem } from '@/types/backend'

withDefaults(defineProps<{
  attributes: AttributesAttributeItem[]
  showSitePid?: boolean
}>(), {
  showSitePid: false
})
</script>
