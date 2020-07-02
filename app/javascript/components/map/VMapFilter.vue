<template>
    <div class="filter-overlay">
        <div class="representative-colour" :style="{ backgroundColor: overlay.colour }"></div>
        <div class="description">{{ overlay.description }}</div>
        <div class="active-toggler" v-if="overlay.isToggleable"></div>
    </div>
</template>
<script>
export default {
    name: 'VMapFilter',
    model: {
        event: 'change',
        prop: 'overlay'
    },
    props: {
        overlay: {
            type: Object,
            required: true,
            validator: overlay => {
                return overlay.hasOwnProperty('colour') && overlay.colour instanceof String
                    && overlay.hasOwnProperty('description') && overlay.description instanceof String
                    && overlay.hasOwnProperty('isToggleable') && overlay.isToggleable instanceof Boolean
            }
        }
    },
    data: function () {
      return {

      }
    }
}
</script>