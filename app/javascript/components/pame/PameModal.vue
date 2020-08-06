<template>
  <div 
    :class="['modal-wrapper', { 'modal--active' : isActive }]"
    @click.self="closeModal()"
  >
    <div class="modal-overlay" />
    <div 
      class="modal--pame"
      id="modal"
    >
      <div class="modal__content">
        <button 
          class="modal__close" 
          @click="closeModal()"
        />

        <h2 class="modal__title">{{ text.modal_title }}</h2>

        <template v-if="modalContent.metadata_id">
          <p><strong>{{ text.id }}:</strong> {{ modalContent.metadata_id }}</p>
        </template>

        <template v-if="modalContent.data_title">
          <p><strong>{{ text.id }}:</strong> {{ modalContent.data_title }}</p>
        </template>

        <template v-if="modalContent.resp_party">
          <p><strong>{{ text.responsible }}:</strong> {{ modalContent.resp_party }}</p>
        </template>

        <template v-if="modalContent.year">
          <p><strong>{{ text.year }}:</strong> {{ modalContent.source_year }}</p>
        </template>

        <template v-if="modalContent.language">
          <p><strong>{{ text.language }}:</strong> {{ modalContent.language }}</p>
        </template>
      </div>
    </div>
  </div>
</template>

<script>
  export default {
    name: 'modal',

    props: {
      text: {
        required: true,
        type: Object // { modal_title: String, id: String, title: String, responsible: String, year: String, language: String }
      }
    },

    data () {
      return {
        isActive: false,
        modalOffset: 0,
        styleObject: {
          top: 0
        },
        modalContent: this.$store.state.pame.modalContent
      }
    },

    mounted () {
      this.$eventHub.$on('openModal', this.openModal)
    },

    methods: {
      openModal () {
        this.modalContent = this.$store.state.pame.modalContent
        
        this.isActive = true
      },

      closeModal () {
        this.isActive = false
      },

      printMultiple (field) {
        // print out the array of values comma separated as a string
        let array = this.modalContent[field]

        if (array !== undefined) {
          return array.join(', ')
        }
      }
    }
  }
</script>