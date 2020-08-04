<template>
  <div class="search search--main">
    <button
      v-if="popout"
      class="search__trigger"
      @click="toggleInput"
    />

    <div
      :class="['search__pane', { 'active': isActive, 'popout': popout }]"
      >

      <input
        ref="input"
        v-model="searchTerm"
        type="text"
        class="search__input"
        :placeholder="placeholder"
        v-on:keyup.enter="submit"
      />

      <i class="search__icon" />

      <button
        v-show="showClose"
        class="search__close"
        @click="closeInput"
      />
    </div>
  </div>
</template>

<script>
export default {
  name: 'search-site-input',

  props: {
    placeholder: {
      type: String,
      required: true
    },
    popout: {
      type: Boolean,
      default: false
    },
    prePopulatedSearchTerm: String
  },

  data () {
    return {
      isActive: true,
      searchTerm: ''
    }
  },

  created () {
    if(this.popout) { this.isActive = false }
  },

  mounted () {
    if(this.prePopulatedSearchTerm) { this.searchTerm = this.prePopulatedSearchTerm }
  },

  computed: {
    showClose () {
      const hasSearchTerm = this.searchTerm.length != 0

      return this.popout ? true : hasSearchTerm
    }
  },

  methods: {
    closeInput () {
      if(this.popout) { this.isActive = false }

      this.searchTerm = ''
    },

    openInput () { this.isActive = true },

    submit () {
      this.$emit('submit:search', this.searchTerm)
    },

    toggleInput () {
      this.isActive = !this.isActive
      setTimeout(() => this.$refs.input.focus(), 0)
    }
  }
}
</script>
