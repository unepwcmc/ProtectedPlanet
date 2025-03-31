<template>
    <ul class="list--stripes" v-if="attributes.length > 0">
      <li class="list__li" :key="`${index}attributes`" v-for="(attribute, index) in attributes">
        <span class="list__title" v-text="attribute.title" />
        <span class="list__value" v-html="attribute.value" />
      </li>
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
    }
  }
}
</script>