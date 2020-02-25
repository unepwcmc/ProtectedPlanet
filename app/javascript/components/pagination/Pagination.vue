<template>
  <div class="pagination">
    <div 
      v-if="haveResults"
      class="pagination__content"
    >
      <span>{{ pageItemsStart }} - {{ pageItemsEnd }} of {{ totalItems }}</span>

      <button 
        v-bind="{ 'disabled' : !previousIsActive }"
        @click="changePage(previousIsActive, 'previous')"
        :class="['pagination__button--previous', { 'button--disabled': !previousIsActive }]"
      />

      <button 
        v-bind="{ 'disabled' : !nextIsActive }"
        @click="changePage(nextIsActive, 'next')"
        :class="['pagination__button--next', { 'button--disabled': !nextIsActive }]"
      />
    </div>

    <p 
      v-else
      v-html="noResultsText"
      class="pagination__no-results"
    />
    
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
        const requestedPage = direction == 'next' ? this.currentPage + 1 : this.currentPage - 1
        
        this.$emit('update:page', requestedPage);
      }
    }
  }
}
</script>