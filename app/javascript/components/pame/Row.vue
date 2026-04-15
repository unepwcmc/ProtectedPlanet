<template>
  <tr class="table__row">
    <td class="table__cell">
      {{ item.name }}
    </td>
    <td class="table__cell">
      {{ item.designation }}
    </td>
    <td class="table__cell">
      <a 
        v-if="item.site_id" 
        :href="item.pa_site_url" 
        title="View protected area on Protected Planet" 
        target="_blank"
      >
        <pame-site-id 
          :site-id="item.site_id" 
          :site-pid="item.site_pid" 
        />
      </a>
      <pame-site-id 
        v-else 
        :site_id="item.site_id" 
        :site_pid="item.site_pid" 
      />
    </td>
    <td class="table__cell">
      {{ item.asmt_id }}
    </td>
    <td class="table__cell">
      {{ checkForMultiples('country') }}
    </td>
    <td class="table__cell">
      {{ item.method }}
    </td>
    <td class="table__cell">
      {{ item.asmt_year }}
    </td>
    <td class="table__cell">
      <a 
        v-if="item.asmt_url.includes('http')" 
        :href="item.asmt_url" 
        title="View assessment" 
        target="_blank"
      >
        Link
      </a>
      <span 
        v-else 
        v-text="item.asmt_url"
      />
    </td> 
    <td
      class="table__cell table__cell-modal-trigger"
      @click="openModal()" 
    >
      {{ item.eff_metaid }}
    </td>
  </tr>
</template>

<script>
import { eventHub } from '../../vue.js'
import PameSiteId from './SiteId.vue'

export default {
  name: "Row",
  props: {
    item: {
      required: true,
      type: Object,
    }
  },
  components: {
    PameSiteId
  },
  computed: {
    projectTitle() {
      return this.trim(this.item.title)
    }
  },

  methods: {
    openModal() {
      this.$store.commit('pame/updateModalContent', this.item)

      this.$eventHub.$emit('openModal')
    },

    checkForMultiples(field) {
      // set output to the first item in the array
      // if the array has more than 1 value then set output to 'multiple'
      let output = this.item[field][0]

      if (this.item[field].length > 1) {
        output = 'Multiple'
      } else {
        output = this.trim(output)
      }

      return output
    },

    trim(phrase) {
      const length = (phrase ? phrase : '').length || 0
      let output

      if (length <= 30) {
        output = phrase
      } else {
        output = phrase.substring(0, 27) + '...'
      }

      return output
    }
  }
}
</script>
<style lang="css">
.pame-row__site-id {
  display: inline-block;
}

.pame-row__site-pid {
  display: inline-block;
}
</style>