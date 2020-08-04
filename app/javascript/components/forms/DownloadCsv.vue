<template>
  <button
    @click="download"
    title="Download CSV file of filtered protected area management effectiveness evaluations"
    class="button--download"
    :class="{ 'button--disabled' : noResults }"
    v-bind="{ 'disabled' : noResults }">
    CSV
  </button>
</template>

<script>
  import axios from 'axios'

  export default {
    name: 'download-csv',

    props: {
      totalItems: {
        required: true,
        type: Number
      }
    },

    computed: {
      noResults () {
        return this.totalItems == 0
      }
    },

    methods: {
      download () {
        console.log('download')
        const csrf = document.querySelectorAll('meta[name="csrf-token"]')[0].getAttribute('content'),
          data = this.$store.state.pame.selectedFilterOptions,
          config = {
            headers: {
              'X-CSRF-Token': csrf,
              'Accept': 'text/csv',
              'responseType': 'blob'
            }
          }

        axios.post('/pame/download', data, config)
          .then((response) => {
            console.log('post successful')
            const date = new Date().toJSON().slice(0,10),
              filename = `protectedplanet-pame-${date}.csv`

            this.createBlob(filename, response.data)
          })
          .catch(function (error) {
            console.log(error)
          })
      },

      createBlob (filename, data) {
        let blob = new Blob([data])
        console.log('blob')

        if (typeof window.navigator.msSaveBlob !== 'undefined') {
          // IE workaround for "HTML7007: One or more blob URLs were 
          // revoked by closing the blob for which they were created. 
          // These URLs will no longer resolve as the data backing 
          // the URL has been freed."
          window.navigator.msSaveBlob(blob, filename)

        } else {
          const blobURL = window.URL.createObjectURL(blob),
            tempLink = document.createElement('a')

          // Safari thinks _blank anchor are pop ups. We only want to set _blank
          // target if the browser does not support the HTML5 download attribute.
          // This allows you to download files in desktop safari if pop up blocking 
          // is enabled.
          if (typeof tempLink.download === 'undefined') {
              tempLink.setAttribute('target', '_blank')
          }
          
          tempLink.href = blobURL
          tempLink.setAttribute('download', filename)
          this.simulateClick(tempLink)
          window.URL.revokeObjectURL(blobURL)
        }
      },

      simulateClick (element) {
        // created because standard .click() doesn't work in Firefox
        const event = new MouseEvent('click', {
          bubbles: true,
          cancelable: true,
          view: window
        })
        // If cancelled, don't dispatch our event
        var canceled = !element.dispatchEvent(event)
      }
    }
  }
</script>
