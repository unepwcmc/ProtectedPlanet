<template>
  <div class="search search--main">
    <button 
      class="search__trigger"
      @click="toggleInput"
    />

    <div 
      :class="['search__pane', { 'active': isActive }]"
      >
      <button 
        class="search__close"
        @click="closeInput"
      />

      <i class="search__icon" />

      <input 
        type="text"
        class="search__input"
      />
    </div>
  </div>
</template>

<script>
export default {
  name: 'search',

  data () {
    return {
      isActive: false
    }
  },

  methods: {
    toggleInput () { this.isActive = !this.isActive },

    openInput () { this.isActive = true },

    closeInput () { this.isActive = false }
  }
}
</script>