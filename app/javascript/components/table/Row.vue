<template>
<tr>
    <td>{{ item.name }}</td>
    <td>{{ item.designation }}</td>
    <td>
      <template v-if="item.restricted">{{ item.wdpa_id }}</template>
      <a v-else :href="wdpaUrl(item.wdpa_id)" title="View protected area on Protected Planet" target="_blank">{{ item.wdpa_id }}</a>
    </td>
    <td>{{ item.id }}</td>
    <td>{{ checkForMultiples('iso3') }}</td>
    <td>{{ item.methodology }}</td>
    <td>{{ item.year }}</td>
    <td v-html="assessmentUrl(item.url)"></td>
    <td @click="openModal()" class="modal__trigger">{{ item.metadata_id }}</td>
  </tr>
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

        eventHub.$emit('openModal')
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
