<template>
  <button @click="download" title="Download CSV file of filtered protected area management effectiveness evaluations"
    class="button--download" :class="{ 'button--disabled': noResults || isLoading }"
    v-bind="{ 'disabled': noResults || isLoading }">
    <span v-if="isLoading" :class="['icon--loading-spinner', 'margin-center', { 'icon-visible': isLoading }]" />
    <span v-else>
      CSV
    </span>
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

  data() {
    return {
      isLoading: false
    }
  },

  computed: {
    noResults() {
      return this.totalItems == 0
    }
  },

  methods: {
    download() {
      if (this.noResults || this.isLoading) return

      this.isLoading = true

      const csrf = document.querySelectorAll('meta[name="csrf-token"]')[0].getAttribute('content')
      const data = this.$store.state.pame.selectedFilterOptions
      const config = {
        responseType: 'blob',
        headers: {
          'X-CSRF-Token': csrf,
          'Accept': 'text/csv'
        }
      }

      axios.post('/pame/download', data, config)
        .then(response => {
          const disposition = response.headers['content-disposition'] || ''
          const match = disposition.match(/filename="?([^"]+)"?/)
          const filename = match ? match[1] : 'download.csv'

          return {
            filename,
            blob: response.data
          }
        })
        .then(({ filename, blob }) => {
          const url = window.URL.createObjectURL(blob)
          const a = document.createElement('a')

          a.href = url
          a.download = filename
          a.click()
          window.URL.revokeObjectURL(url)

          this.$ga.event('Button', 'click', 'PAME - CSV download')
          this.isLoading = false
        })
        .catch((error) => {
          console.log(error)
          this.isLoading = false
        })
    }
  }
}
</script>
