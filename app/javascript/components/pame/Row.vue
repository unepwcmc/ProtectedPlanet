<template>
  <div class="table__row">
    <p class="table__cell">{{ item.name }}</p>
    <p class="table__cell">{{ item.designation }}</p>
    <p class="table__cell">
      <a v-if="item.site_id" 
        :href="linkToPAUrl" 
        title="View protected area on Protected Planet" 
        target="_blank">
        <pame-site-id 
          :site_id="item.site_id" 
          :site_pid="item.site_pid" 
        />
      </a>
      <pame-site-id 
        v-else
        :site_id="item.site_id"
        :site_pid="item.site_pid"
      />
    </p>
    <p class="table__cell">{{ item.asmt_id }}</p>
    <p class="table__cell">{{ checkForMultiples('country') }}</p>
    <p class="table__cell">{{ item.method }}</p>
    <p class="table__cell">{{ item.asmt_year }}</p>
    <p 
      v-html="assessmentUrl(item.asmt_url)"
      class="table__cell"
    />
    <p 
      @click="openModal()" 
      class="table__cell table__cell-modal-trigger"
    >
      {{ item.eff_metaid }}
    </p>
  </div>
</template>

<script>
  import { eventHub } from '../../vue.js'
  import PameSiteId from './SiteId.vue'

  export default {
    name: "row",
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
      projectTitle () {
        return this.trim(this.item.title)
      },
      linkToPAUrl () {
        return this.item.site_pid ? 
        `${this.item.pa_site_url}?pid=${this.item.site_pid}`
         : this.item.pa_site_url
      }
    },

    methods: {
      assessmentUrl (url) {
        return url.includes('http') ? `<a href="${url}" title="View assessment" target="_blank">Link</a>` :  url
      },

      openModal () {
        this.$store.commit('pame/updateModalContent', this.item)

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
        const length = phrase?.length ?? 0
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
<style lang="css">
.pame-row__site-id {
  display: inline-block;
}

.pame-row__site-pid {
  display: inline-block;
}
</style>