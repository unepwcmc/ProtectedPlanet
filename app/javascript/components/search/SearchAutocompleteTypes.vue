<template>
  <div
    class="search--autocomplete"
  >
    <div class="search__search">
      <i class="search__search-icon" /> 

      <input
        v-model="searchTerm"
        class="search__search-input"
        type="text"
        placeholder="placeholder"
        v-on:keyup="updateAutocomplete"
      >
    </div>

    <button 
      v-show="showResetIcon"
      class="search__search-icon--delete"
      @click="resetSearchTerm"
    />

    <ul 
      v-show="autocomplete.length > 0" 
      role="listbox" 
      class="search__dropdown"
    >
      <li
        v-for="(option, index) in autocomplete"
        :key="option.id"
        class="search__li"
        role="option"
      >
        <a 
          class="search__a"
          :href="option.url"
          v-html="option.title"
        />
      </li>
    </ul>

    <div class="select--types">
      <div 
        :class="['select__label', {'active': typeDropdownActive}]"
        @click="toggleTypes"
      >
        {{ selectedTypeName }}
      </div>

      <ul :class="['select__ul', {'active': typeDropdownActive}]">
        <li 
          v-for="type, index in types"
          class="select__li"
          @click="updateType(index)"
        >
          {{ type.name }}
        </li>
      </ul>
    </div>
  </div>
</template>

<script>
import axios from 'axios'
import { setCsrfToken } from '../../helpers/request-helpers'
import mixinPopupCloseListeners from '../../mixins/mixin-popup-close-listeners'

export default {
  name: 'SearchAutocompleteTypes',

  mixins: [
    mixinPopupCloseListeners({closeCallback: 'closeSelect'}),
  ],

  props: {
    types: {
      default: () => [],
      type: Array // [ { name: String, options: [ { id: Number, name: String } ] } ]
    },
    endpoint: {
      required: true,
      type: String
    }
  },

  data () {
    return {
      typeIndex: 0,
      typeDropdownActive: false,
      searchTerm: '',
      autocomplete: [] // [ { title: String, url: String ]
    }
  },

  computed: {
    hasAutocompleteOptions () {
      this.autocomplete.length > 0
    },
    options () {
      return this.types[this.typeIndex].options
    },
    selectedTypeName () {
      return this.types[this.typeIndex].name
    },
    showResetIcon () {
      return this.searchTerm.length != 0
    }
  },

 

  mounted () {
    // this.addTabFromSearchListener()
    // this.addArrowKeyListeners()
    // this.addTabForwardFromResetListener()
  },

  methods: {
    updateAutocomplete () {
      if(this.searchTerm.length == 0) { 
        this.resetAutocomplete() 
        return false
      }

      //axios 
      console.log('update')

      let data = {
        params: {
          type: this.selectedTypeName,
          search_term: this.searchTerm
        }
      }

      axios.post(this.endpoint, data)
      .then(response => {
        console.log(success)
        this.autocomplete = response.data.autocomplete
      })
      .catch(function (error) {
        console.log(error)
      })
    },

    updateType (index) {
      this.typeIndex = index
      this.toggleTypes()
      this.resetSearchTerm()
      this.resetAutocomplete()
    },

    toggleTypes () {
      this.typeDropdownActive = !this.typeDropdownActive
    },

    resetSearchTerm () {
      this.searchTerm = ''
      this.resetAutocomplete()
    },

    resetAutocomplete () {
      this.autocomplete = []
    }
  }
}
</script>