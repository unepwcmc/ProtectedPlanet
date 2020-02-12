<template>
  <div
    class="select--autocomplete"
  >
    <div class="select__search">
      <i class="select__search-icon" /> 

      <input
        v-model="searchTerm"
        class="select__search-input"
        type="text"
        placeholder="placeholder"
        v-on:keyup="updateAutocomplete"
      >
    </div>

    <button 
      v-show="showResetIcon"
      class="select__search-icon--delete"
      @click="resetSearchTerm"
    />

    <ul 
      v-show="autocomplete.length > 0" 
      role="listbox" 
      class="select__dropdown"
    >
      <li
        v-for="(option, index) in autocomplete"
        :key="option.id"
        class="select__li"
        role="option"
      >
        <a 
          class="select__a"
          href="option.url"
          v-html="option.title"
        />
      </li>
    </ul>

    <div class="select--categories">
      <div 
        class="select__label"
        @click="toggleCategories"
      >
        {{ selectedCategoryName }}
      </div>

      <ul :class="['select__ul', {'active': categoriesActive}]">
        <li 
          v-for="category, index in categories"
          class="select__li"
          @click="updateCategory(index)"
        >
          {{ category.name }}
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
  name: 'SearchAutocompleteCategories',

  mixins: [
    mixinPopupCloseListeners({closeCallback: 'closeSelect'}),
  ],

  props: {
    categories: {
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
      categoryIndex: 0,
      categoriesActive: false,
      searchTerm: '',
      autocomplete: [] // [ { title: String, url: String ]
    }
  },

  computed: {
    hasAutocompleteOptions () {
      this.autocomplete.length > 0
    },
    options () {
      return this.categories[this.categoryIndex].options
    },
    selectedCategoryName () {
      return this.categories[this.categoryIndex].name
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
          type: this.selectedCategoryName,
          search_term: this.searchTerm
        }
      }

      // axios.post(this.endpoint, data)
      // .then(response => {
      //   console.log(success)
      //   this.autocomplete = response.data.autocomplete
      // })
      // .catch(function (error) {
      //   console.log(error)
      // })

      this.autocomplete = [
        { title: 'option 1', url: '/en/1'},
        { title: 'option 2', url: '/en/2'}
      ]
    },

    updateCategory (index) {
      this.categoryIndex = index
      this.toggleCategories()
      this.resetSearchTerm()
      this.resetAutocomplete()
    },

    toggleCategories () {
      this.categoriesActive = !this.categoriesActive
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