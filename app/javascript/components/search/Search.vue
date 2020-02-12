<template>
  <div class="search search--main">
    <button 
      class="search__trigger"
      @click="toggleInput"
    />

    <div 
      :class="['search__pane', { 'active': isActive }]"
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
    }
  },

  data () {
    return {
      isActive: false,
      searchTerm: ''
    }
  },

  methods: {
    toggleInput () { this.isActive = !this.isActive },

    openInput () { this.isActive = true },

    closeInput () { 
      this.isActive = false 
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