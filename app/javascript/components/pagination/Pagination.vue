<template>
  <div>
    <div v-if="haveResults" class="right">
      <span class="bold">{{ pageItemsStart }} - {{ pageItemsEnd }} of {{ totalItems }}</span>

      <button 
        v-bind="{ 'disabled' : !previousIsActive }"
        @click="changePage(previousIsActive, 'previous')"
        class="button button--previous"
        :class="{ 'button--disabled': !previousIsActive }">
      </button>

      <button 
        v-bind="{ 'disabled' : !nextIsActive }"
        @click="changePage(nextIsActive, 'next')"
        class="button button--next"
        :class="{ 'button--disabled': !nextIsActive }">
      </button>
    </div>

    <div v-else class="left">
      <p 
        v-html="noResultsText"
        class="pagination__no-results"
      />
    </div>
  </div>
</template>

<script>
export default {
  name: 'pagination',

  props: {
    currentPage: {
      type: Number,
      required: true
    },
    noResultsText: {
      type: String,
      required: true  
    },
    pageItemsEnd: {
      type: Number,
      required: true
    },
    pageItemsStart: {
      type: Number,
      required: true
    },
    totalItems: {
      type: Number,
      required: true
    }
  },
  
  computed: {
    haveResults () {
      return this.totalItems > 0
    },

    nextIsActive () {
      return  this.pageItemsEnd < this.totalItems
    },

    previousIsActive () {
      return this.currentPage > 1
    },
  },

  methods: {
    changePage (isActive, direction) {
      if (isActive) {
        const newPage = direction == 'next' ? this.currentPage + 1 : this.currentPage - 1
        
        this.$store.commit('updateRequestedPage', newPage)
        eventHub.$emit('getNewItems')
      }
    }
  }
}
</script>