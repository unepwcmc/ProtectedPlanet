<template>
  <div
    class="modal-wrapper--download-commercial"
    :class="{ active: isActive }"
  >
    <div
      class="modal--download-commercial"
      :class="{ active: isActive }"
    >
      <span
        class="modal__close"
        @click="emit('close')"
      />
      <h4
        class="modal__title"
        v-text="text.title"
      />
      <div class="modal__links">
        <div class="modal__link">
          <span
            class="modal__link-title"
            v-text="text.commercialTitle"
          />
          <span
            class="modal__link-text"
            v-html="text.commercialText"
          />
        </div>

        <span class="modal__divider" />

        <div class="modal__link">
          <span
            class="modal__link-title"
            v-text="text.nonCommercialTitle"
          />
          <span
            class="modal__link-text"
            v-text="text.nonCommercialText"
          />
          <button
            class="modal__link-button"
            @click="emit('nonCommercial')"
          >
            <span
              class="modal__link-button-text"
              v-text="text.nonCommercialButton"
            />
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { DownloadProps } from '@/types/backend'

withDefaults(defineProps<{
  isActive?: boolean
  text: DownloadProps['textCommercial']
}>(), {
  isActive: false
})

const emit = defineEmits<{ close: [], nonCommercial: [] }>()
</script>
