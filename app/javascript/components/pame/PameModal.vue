<template>
  <div 
    :class="['modal-wrapper', { 'modal--active' : isActive }]"
    @click.self="closeModal()"
  >
    <div class="modal-overlay" />
    <div 
      class="modal--pame"
      id="modal"
      :style="styleObject" 
    >
      <div class="modal__content">
        <button 
          class="modal__close" 
          @click="closeModal()"
        />

        <h2 class="modal__title">{{ text.modal_title }}</h2>

        <template v-if="hasContent(modalContent.metadata_id)">
          <p><strong>{{ text.id }}:</strong> {{ modalContent.metadata_id }}</p>
        </template>

        <template v-if="hasContent(modalContent.data_title)">
          <p><strong>{{ text.id }}:</strong> {{ modalContent.data_title }}</p>
        </template>

        <template v-if="hasContent(modalContent.resp_party)">
          <p><strong>{{ text.responsible }}:</strong> {{ modalContent.resp_party }}</p>
        </template>

        <template v-if="hasContent(modalContent.year)">
          <p><strong>{{ text.year }}:</strong> {{ modalContent.source_year }}</p>
        </template>

        <template v-if="hasContent(modalContent.language)">
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

        // delay calculating the modal height so that the data can update which will increase the height of the modal
        window.setTimeout(() => {
          // calculate modal offset
          var modalHeight = document.getElementById('modal').clientHeight
          var windowHeight = window.innerHeight

          // if the modal is smaller than the screen it is being viewed on
          // then vertically centre it on the screen
          if (modalHeight < windowHeight) {
            var modalOffset = (windowHeight - modalHeight) / 2

            this.modalOffset = window.pageYOffset + modalOffset
          } else {
            this.modalOffset = window.pageYOffset
          }

          this.styleObject.top = this.modalOffset + 'px'

          this.isActive = !this.isActive
        }, 100)
      },

      closeModal () {
        this.isActive = !this.isActive
      },

      printMultiple (field) {
        // print out the array of values comma separated as a string
        let array = this.modalContent[field]

        if (array !== undefined) {
          return array.join(', ')
        }
      },

      hasContent (property) {
        return !!property
      }
    }
  }
</script>