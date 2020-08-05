<template>
  <div class="modal-wrapper" :class="{ 'modal--active' : isActive }" @click.self="closeModal()">
    <div id="modal" :style="styleObject" class="modal--pame">
      <div class="modal__content">
        <button class="modal__close" @click="closeModal()"></button>

        <h2>Source details</h2>

        <template v-if="hasContent(modalContent.metadata_id)">
          <p><strong>MetadataID:</strong> {{ modalContent.metadata_id }}</p>
        </template>

        <template v-if="hasContent(modalContent.data_title)">
          <p><strong>Data title:</strong> {{ modalContent.data_title }}</p>
        </template>

        <template v-if="hasContent(modalContent.resp_party)">
          <p><strong>Responsible party:</strong> {{ modalContent.resp_party }}</p>
        </template>

        <template v-if="hasContent(modalContent.year)">
          <p><strong>Year of submission:</strong> {{ modalContent.source_year }}</p>
        </template>

        <template v-if="hasContent(modalContent.language)">
          <p><strong>Language:</strong> {{ modalContent.language }}</p>
        </template>
      </div>
    </div>
  </div>
</template>

<script>
  export default {
    name: 'modal',

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
        console.log('optn')
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