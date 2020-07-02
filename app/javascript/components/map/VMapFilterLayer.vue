<template>
    <div class="filter-layer">
        <div class="representative-colour" :style="{ backgroundColor: layer.colour }"></div>
        <div class="description">{{ layer.description }}</div>
        <div class="active-toggler" v-if="layer.isToggleable"></div>
    </div>
</template>
<script>
export default {
    name: "VMapFilterLayer",
    model: {
        event: 'change',
        prop: 'layer'
    },
    props: {
        layer: {
            type: Object,
            validator: type => {
                return type.hasOwnProperty('colour') && type.colour instanceof String
                    && type.hasOwnProperty('description') && type.description instanceof String
                    && type.hasOwnProperty('isToggleable') && type.isToggleable instanceof Boolean
            }
        }
    }
}
</script>