<template>
    <div class="v-map-toggler" 
        :class="{ 'v-map-toggler__active': active }"
        @click.stop="$emit('change', !active)"
    >
        <div class="switch">{{ actionText }}</div>
    </div>
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
        },
        onText: {
            type: String,
            default: 'ON',
        },
        offText: {
            type: String,
            default: 'OFF'
        }
    },
    computed: {
        actionText: function () {
            if (this.active) {
                return this.onText
            }
            return this.offText
        }
    }
}
</script>
<style lang="scss" scoped>
.v-map-toggler {
    cursor: pointer;
}
</style>