<template>
    <div class="v-map-toggler" @click="$emit('change', !active)"></div>
</template>
<script>
export default {
    model: {
        event: 'change',
        prop: 'active'
    },
    props: {
        active: {
            type: Boolean,
            required: true
        }
    }
}
</script>