<template>
  <div v-if="hasOptions" class="filter">
    <p
      @click="openSelect()" 
      class="filter__button button" 
      :class="{ 'filter__button--active' : isOpen , 'filter__button--has-selected' : hasSelected }">

      {{ title }} <span v-show="hasSelected" class="filter__button-total">{{ totalSelectedOptions }}</span>
    </p>
    
    <div class="filter__options" :class="{ 'filter__options--active' : isOpen }">
      <ul class="ul-unstyled filter__options-list" :class="filterClass">
        <data-filter-option v-for="option in options" 
          :option="option"
          :selected="false">
        </data-filter-option>
      </ul>

      <div class="filter__buttons">
        <button @click="clear()" class="button--link-bold">Clear</button>
        <button @click="cancel()" class="button--link filter__button-cancel">Cancel</button>
        <button @click="apply()" class="button--link-bold">Apply</button>
      </div>
    </div>
  </div>
</template>

<script>
  import { eventHub } from '../../vue.js'
  import DataFilterOption from './DataFilterOption.vue'

  export default {
    name: 'data-filter',

    components: { DataFilterOption },

    props: {
      name: {
        type: String
      },
      title: {
        required: true, 
        type: String
      },
      options: {
        type: Array
      },
      type: {
        type: String
      }
    },

    data () {
      return {
        children: this.$children,
        isOpen: false,
        activeOptions: []
      }
    },

    computed: {
      // only show the select if the filter is a real filter and not just a table title
      hasOptions () {
        return this.options != undefined || this.name != undefined
      },

      selectedOptions () {
        let selectedArray = []

        this.children.forEach(child => {
          if(child.isSelected){ 
            selectedArray.push(child.option) 
          }
        })

        return selectedArray
      },

      hasSelected () {
        return this.totalSelectedOptions > 0
      },

      totalSelectedOptions () {
        return this.selectedOptions.length
      },

      filterClass () {
        return 'filter__options--' + this.name.replace('_| |(|)', '-').toLowerCase()
      }
    },

    methods: {
      openSelect () {
        // if the filter is open is close it, else open it and close the others
        if(this.isOpen){
          this.isOpen = false
        } else {
          this.$eventHub.$emit('clickDropdown', this.name)  
        }
      },

      closeSelect () {
        this.isOpen = false
      },

      cancel() {
        this.closeSelect()
        
        // reset each option to the correct state
        this.children.forEach(child => {
          child.isSelected = this.activeOptions.includes(child.option) ? true : false
        })
      },

      clear () {
        // set the isSelected property on all options to false
        this.children.forEach(child => {
          child.isSelected = false
        })
      },

      apply () {
        this.closeSelect()
        //update the active filters array
        this.activeOptions = this.selectedOptions

        const newFilterOptions = {
          filter: this.name,
          options: this.activeOptions
        }

        this.$store.commit('updateFilterOptions', newFilterOptions)
        this.$store.commit('updateRequestedPage', 1)
        this.$eventHub.$emit('getNewItems')
      }
    }
  }
</script>
