<template>
  <div class="pagination right">
    <div 
      v-if="haveResults"
      class="pagination__content" 
    >
      <span class="bold">{{ firstItem }} - {{ lastItem }} of {{ totalItems }}</span>

      <button
        class="pagination__button--previous" 
        :class="{ 'button--disabled': !previousIsActive }" 
        v-bind="{ 'disabled': !previousIsActive }" 
        @click="changePage(previousIsActive, 'previous')"
      />
      <button
        class="pagination__button--next" 
        :class="{ 'button--disabled': !nextIsActive }"
        v-bind="{ 'disabled': !nextIsActive }" 
        @click="changePage(nextIsActive, 'next')"
      />
    </div>
    <div 
      v-else 
      class="left"
    >
      <p>There are no records matching the selected filters</p>
    </div>
  </div>
</template>

<script>

export default {
  name: 'PamePagination',

  props: {
    currentPage: {
      required: true,
      type: Number
    },
    itemsPerPage: {
      required: true,
      type: Number
    },
    totalItems: {
      required: true,
      type: Number
    },
    totalPages: {
      required: true,
      type: Number
    }
  },

  computed: {
    nextIsActive() {
      return this.currentPage < this.totalPages
    },

    previousIsActive() {
      return this.currentPage > 1
    },

    firstItem() {
      let first

      if (this.totalItems == 0) {
        first = 0

      } else if (this.totalItems < this.itemsPerPage) {
        first = 1

      } else {
        first = this.itemsPerPage * (this.currentPage - 1) + 1
      }

      return first
    },

    lastItem() {
      let lastItem = this.itemsPerPage * this.currentPage

      if (lastItem > this.totalItems) {
        lastItem = this.totalItems
      }

      return lastItem
    },

    haveResults() {
      return this.totalItems > 0
    }


  },

  methods: {
    changePage(isActive, direction) {
      // only change the page if the button is active
      if (isActive) {
        const newPage = direction == 'next' ? this.currentPage + 1 : this.currentPage - 1

        this.$store.commit('pame/updateRequestedPage', newPage)
        this.$emit('updated:page')
      }
    }
  }
}
</script>
