<template>
  <div class="table__row">
    <p class="table__cell">{{ item.name }}</p>
    <p class="table__cell">{{ item.designation }}</p>
    <p class="table__cell">
      <template v-if="item.restricted">{{ item.wdpa_id }}</template>
      <a v-else :href="wdpaUrl(item.wdpa_id)" title="View protected area on Protected Planet" target="_blank">{{ item.wdpa_id }}</a>
    </p>
    <p class="table__cell">{{ item.id }}</p>
    <p class="table__cell">{{ checkForMultiples('iso3') }}</p>
    <p class="table__cell">{{ item.methodology }}</p>
    <p class="table__cell">{{ item.year }}</p>
    <p 
      v-html="assessmentUrl(item.url)"
      class="table__cell"
    />
    <p 
      @click="openModal()" 
      class="table__cell modal__trigger"
    >
      {{ item.metadata_id }}
    </p>
  </div>
</template>

<script>
  import { eventHub } from '../../vue.js'

  export default {
    name: "row",
    props: {
      item: {
        required: true,
        type: Object,
      }
    },

    computed: {
      projectTitle () {
        return this.trim(this.item.title)
      }
    },

    methods: {
      wdpaUrl (wdpaId) {
        return `https://protectedplanet.net/${wdpaId}`
      },

      assessmentUrl (url) {
        return url.includes('http') ? `<a href="${url}" title="View assessment" target="_blank">Link</a>` :  url
      },

      openModal () {
        this.$store.commit('updateModalContent', this.item)

        this.$eventHub.$emit('openModal')
      },

      checkForMultiples (field) {
        // set output to the first item in the array
        // if the array has more than 1 value then set output to 'multiple'
        let output = this.item[field][0]

        if(this.item[field].length > 1) {
          output = 'Multiple'
        } else {
          output = this.trim(output)
        }

        return output
      },

      trim (phrase) {
        const length = phrase.length
        let output

        if (length <= 30) {
          output = phrase
        } else {
          output = phrase.substring(0,27) + '...'
        }

        return output
      }
    }
  }
</script>
