<template>
  <div v-show="isActive">
    <div class="filter__pane">
      <div class="filter__filter-groups">
        <div 
          v-for="filterGroup in filterGroups"
          class="filter__group"
        >
          <h3>{{ filterGroup.title }}</h3>

          <v-filter 
            v-for="filter in filterGroup.filters"
            :id="filter.id"
            :name="filter.name"
            :options="filter.options"
            :title="filter.title"
            :type="filter.type"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import vFilter from './vFilter'

export default {
  name: 'filters-search',

  components: { vFilter },

  props: {
    isActive: {
      required: true,
      type: Boolean
    }
  },

  data () {
    return {
      filterGroups: [
        {
          title: 'View by',
          filters: [
            {
              id: 'type',
              name: 'type',
              options: [ { id: 'all', title: 'All' }, { id: 'regions', title: 'Regions' } ],
              type: 'radio'
            }
          ]
        },
        {
          title: 'Filter by',
          filters: [
            {
              id: 'type',
              name: 'type',
              options: [ { id: 'marine', title: 'Marine' }, { id: 'terrestrial', title: 'Terrestrial' }, { id: 'green-list', title: 'Green List' } ],
              title: 'Type',
              type: 'checkbox'
            },
            {
              id: 'designation',
              name: 'designation',
              options: [ { id: 'designation-1', title: 'Designation 1' }, { id: 'designation-2', title: 'Designation 2' } ],
              title: 'Designation',
              type: 'checkbox'
            },
            {
              id: 'governance',
              name: 'governance',
              options: [ { id: 'governance-1', title: 'Governance 1' }, { id: 'governance-2', title: 'Governance 2' } ],
              title: 'Governance',
              type: 'checkbox'
            },
            {
              id: 'iucn-category',
              name: 'iucn-category',
              options: [ { id: 'iucn-category-1', title: 'IUCN Category 1' }, { id: 'iucn-category-2', title: 'IUCN Category 2' } ],
              title: 'IUCN Category',
              type: 'checkbox'
            }
          ]
        }
      ]
    }
  }
}
</script>