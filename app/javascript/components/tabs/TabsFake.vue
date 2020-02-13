<template>
  <ul class="tabs--fake">
    <li 
      v-for="(child, index) in children" 
      :key="getId(index)"
      :class="['tab__trigger', { 'active': child.isActive }]"
      @click="click(child.id)"
    >
      {{ child.title }}
    </li>
  </ul>
</template>

<script>
export default {
  name: 'TabsFake',

  props: {
    children: {
      type: Array, 
      required: true
    }
  },

  methods: {
    click (selectedId) {
      this.children.forEach(child => {
        child.isActive = child.id === selectedId
      })

      this.$emit('tab-clicked', selectedId)
    },

    getId (index) {
      return `tab-${this.id}-${index}`
    }
  }
}
</script>