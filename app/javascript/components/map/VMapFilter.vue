<template>
    <div class="v-map-filter">
        <div class="color" :style="{ backgroundColor: color }"></div>
        <div class="description">{{ description }}</div>
        <div class="active-toggler" v-if="isToggleable">
            <v-map-toggler v-model="isActive" @change="$emit('isActive', $event)" />
        </div>
    </div>
</template>
<script>
import VMapToggler from './VMapToggler'

export default {
    name: 'VMapFilter',

    components: {
        VMapToggler,
    },
    
    props: {
        color: {
            type: String,
            default: '#cccccc'
        },
        description: {
            type: String,
            required: true
        },
        isShownByDefault: {
            type: Boolean,
            default: true
        },
        isToggleable: {
            type: Boolean,
            default: true
        }

    },
    data: function () {
        return {
            isActive: this.isShownByDefault === true
        }
    }
}
</script>