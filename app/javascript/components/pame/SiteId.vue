<template>
  <span class="pame-site-id">
    <span class="pame-site-id__site-id">{{ siteId }}</span>
    <span 
      v-if="showParcelId" 
      class="pame-site-id__site-pid"
    >
      <span class="pame-site-id__site-pid-label">/</span>
      <span>{{ sitePid }}</span>
    </span>
  </span>
</template>

<script>
export default {
  name: 'PameSiteId',
  props: {
    siteId: {
      required: true,
      type: Number,
    },
    sitePid: {
      required: true,
      type: String,
    },
  },
  computed: {
    showParcelId() {
      return String(this.sitePid) !== String(this.siteId)
    }
  }
}
</script>