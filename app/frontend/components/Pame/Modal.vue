<template>
  <div
    class="modal-wrapper"
    :class="{ 'modal--active': pameStore.isModalOpen }"
    @click.self="onClose"
  >
    <div class="modal-overlay" />
    <div
      id="modal"
      class="modal--pame"
    >
      <div class="modal__content">
        <button
          class="modal__close"
          @click="onClose"
        />

        <h2
          class="modal__title"
          v-text="text.modal_title"
        />

        <p v-if="modalContent?.eff_metaid">
          <strong v-text="`${text.id}:`" />
          <span v-text="modalContent.eff_metaid" />
        </p>

        <p v-if="modalContent?.data_title">
          <strong v-text="`${text.title}:`" />
          <span v-text="modalContent.data_title" />
        </p>

        <p v-if="modalContent?.resp_party">
          <strong v-text="`${text.responsible}:`" />
          <span v-text="modalContent.resp_party" />
        </p>

        <p v-if="modalContent?.source_year">
          <strong v-text="`${text.year}:`" />
          <span v-text="modalContent.source_year" />
        </p>

        <p v-if="modalContent?.language">
          <strong v-text="`${text.language}:`" />
          <span v-text="modalContent.language" />
        </p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { usePameStore } from '@/stores/usePameStore'
import type { PameModalProps } from '@/types/backend'

type PameModal = PameModalProps
defineProps<PameModal>()

const pameStore = usePameStore()
const { modalContent } = storeToRefs(pameStore)

function onClose() {
  pameStore.closeModal()
}
</script>
