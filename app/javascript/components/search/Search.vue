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
import axios from 'axios'
import { setCsrfToken } from '../../helpers/request-helpers'

export default {
  name: 'search',

  props: {
    endpoint: {
      type: String,
      required: true
    },
    placeholder: {
      type: String,
      required: true
    },
    popout: {
      type: Boolean,
      default: false
    }
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

  computed: {
    showClose () {
      const hasSearchTerm = this.searchTerm.length != 0

      return this.popout ? true : hasSearchTerm
    }
  },

  methods: {
    toggleInput () { this.isActive = !this.isActive },

    openInput () { this.isActive = true },

    closeInput () { 
      if(this.popout) { this.isActive = false }

      this.searchTerm = ''
    },

    submit () {
      let data = {
        params: {
          search_term: this.searchTerm
        }
      }
        
      axios.post(this.endpoint, data)
      .then(response => {
        console.log(success)
      })
      .catch(function (error) {
        console.log(error)
      })
    }
  }
}
</script>