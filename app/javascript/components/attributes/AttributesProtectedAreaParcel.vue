<template>
    <ul class="list--stripes" v-if="attributes.length > 0">
      <template v-for="(attribute, index) in attributes" >
        <li class="list__li" :key="`${index}parcelattribute`" v-if="showCurrentAttribute(attribute)">
          <span class="list__title" v-text="attribute.title" />
          <span class="list__value" v-html="attribute.value" />
        </li>
      </template>
    </ul> 
</template>

<script>
import Dropdown from '../dropdown/Dropdown.vue'

export default {
  name: "statsAttributes",
  components: { Dropdown },
  props: {
    attributes: {
      type: Array,
      required: true
    },
    showSitePid: {
      type: Boolean,
      default: false
    }
  },
  methods: {
    showCurrentAttribute(attribute) {
      let showCurrent = true

      if(!this.showSitePid && attribute.is_site_pid) {
        showCurrent = false
      }
      
      return showCurrent
    }
  }
}
</script>