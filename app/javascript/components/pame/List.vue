<template>
  <tr class="table__list">
    <td 
      class="table__list-items" 
      :class="{ 'table__list-items--last': isLast }"
    >
      <p class="table__list-item table__list-item--name">
        <span class="table__list-item-label">{{ attributes[0].title }}:</span> 
        <span class="table__list-item-value">{{ item.name }}</span>
      </p>
      <p class="table__list-item table__list-item--designation">
        <span class="table__list-item-label">{{ attributes[1].title }}:</span> 
        <span class="table__list-item-value">{{ item.designation }}</span>
      </p>
      <p class="table__list-item able__list-item--site-id">
        <span class="table__list-item-label">{{ attributes[2].title }}:</span> 
        <span class="table__list-item-value">
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
        </span>
      </p>
      <p class="table__list-item table__list-item--assessment-id">
        <span class="table__list-item-label">{{ attributes[3].title }}:</span> 
        <span class="table__list-item-value">{{ item.asmt_id }}</span>
      </p>
      <p class="table__list-item table__list-item--country">
        <span class="table__list-item-label">{{ attributes[4].title }}:</span> 
        <span class="table__list-item-value">{{ checkForMultiples('country') }}</span>
      </p>
      <p class="table__list-item table__list-item--method">
        <span class="table__list-item-label">{{ attributes[5].title }}:</span> 
        <span class="table__list-item-value">{{ item.method }}</span>
      </p>
      <p class="table__list-item table__list-item--year-of-assessment">
        <span class="table__list-item-label">{{ attributes[6].title }}:</span> 
        <span class="table__list-item-value">{{ item.asmt_year }}</span>
      </p>
      <p class="table__list-item table__list-item--link-to-assessment">
        <span class="table__list-item-label">{{ attributes[7].title }}:</span> 
        <span class="table__list-item-value">
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
        </span>
      </p> 
      <p
        class="table__list-item table__list-item--metadata-id table__cell-modal-trigger"
        @click="openModal()" 
      >
        <span class="table__list-item-label">{{ attributes[8].title }}:</span>
        <span class="table__list-item-value">{{ item.eff_metaid }}</span>
      </p>
    </td>
  </tr>
</template>

<script>
import PameSiteId from './SiteId.vue'

export default {
  name: 'RowMobile',
  components: {
    PameSiteId
  },
  props: {
    item: {
      required: true,
      type: Object,
    },
    isLast: {
      required: false,
      type: Boolean,
      default: false
    },
    attributes: {
      required: true,
      type: Array,
    }
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