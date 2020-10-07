<template>
  <a 
    :id="link.id" 
    role="menuitem" 
    :class="[{'is-current-page': link.is_current_page}, 'nav__a']" 
    :href="link.url" 
  >
    {{link.label}}
  </a>
</template>

<script>
export default {
  name: 'nav-link',

  props: {
    link: { //{ id: String, label: String, url: String }
      required: true,
      type: Object
    }
  },

  methods: {
    click () {
      this.$emit('scroll', this.item.id)
    }
  }
}
</script>
