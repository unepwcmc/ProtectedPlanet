<template>
  <div
    class="ct-pame-modal"
    :class="{ 'ct-pame-modal--active': isModalOpen }"
    @click.self="onClose"
  >
    <div class="ct-pame-modal__overlay" />
    <div
      id="modal"
      class="ct-pame-modal__dialog"
    >
      <div class="ct-pame-modal__top">
        <button
          class="ct-pame-modal__close"
          aria-label="Close dialog"
          @click="onClose"
        >
          <IconClose class="ct-pame-modal__close-icon" />
        </button>
      </div>
      <div class="ct-pame-modal__content">
        <h2
          class="ct-pame-modal__title"
          v-text="text.modal_title"
        />
        <div class="ct-pame-modal__info">
          <p
            v-if="modalContent?.eff_metaid"
            class="ct-pame-modal__text"
          >
            <strong v-text="`${text.id}:`" />
            <span v-text="modalContent.eff_metaid" />
          </p>

          <p
            v-if="modalContent?.data_title"
            class="ct-pame-modal__text"
          >
            <strong v-text="`${text.title}:`" />
            <span v-text="modalContent.data_title" />
          </p>

          <p
            v-if="modalContent?.resp_party"
            class="ct-pame-modal__text"
          >
            <strong v-text="`${text.responsible}:`" />
            <span v-text="modalContent.resp_party" />
          </p>

          <p
            v-if="modalContent?.source_year"
            class="ct-pame-modal__text"
          >
            <strong v-text="`${text.year}:`" />
            <span v-text="modalContent.source_year" />
          </p>

          <p
            v-if="modalContent?.language"
            class="ct-pame-modal__text"
          >
            <strong v-text="`${text.language}:`" />
            <span v-text="modalContent.language" />
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import IconClose from '@/components/Icon/Close.vue'
import type { PameEvaluationItem, PameModalTranslations } from '@/types/backend'

defineProps<{
  text: PameModalTranslations
  modalContent: PameEvaluationItem | null
  isModalOpen: boolean
}>()

const emit = defineEmits<{ close: [] }>()

function onClose() {
  emit('close')
}
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-pame-modal {
  @apply hidden;
}

.ct-pame-modal--active {
  @apply block;
}

.ct-pame-modal__overlay {
  @apply
  fixed
  inset-0
  z-10
  bg-theme-grey/80;
}

.ct-pame-modal__dialog {
  @apply
  fixed
  top-0
  left-0
  z-400
  h-screen
  w-full
  bg-white
  py-8.5
  px-8
  md:top-1/2
  md:left-1/2
  md:h-auto
  md:w-3/5
  md:-translate-x-1/2
  md:-translate-y-1/2
  md:tw-shared-border-radius
  tw-shared-base-flex-col;
}

.ct-pame-modal__top {
  @apply
  flex
  justify-end;
}

.ct-pame-modal__content {
  @apply tw-shared-base-flex-col-gap-6;
}

.ct-pame-modal__info {
  @apply tw-shared-base-flex-col-gap-3;
}

.ct-pame-modal__title {
  @apply tw-shared-font-playfair__semi-bold-xl-md-2xl-grey-black;
}

.ct-pame-modal__text {
  strong {
    @apply tw-shared-font-hind-siliguri__semibold-base-grey-black;
  }

  span {
    @apply
    tw-shared-font-hind-siliguri__light-base-grey-black
    ml-1;
  }
}

.ct-pame-modal__close {
  @apply
  tw-shared-button-basic
  cursor-pointer;
}

.ct-pame-modal__close-icon {
  @apply size-5;
}

</style>
