<template>
    <span class="pame-site-id">
        <span class="pame-site-id__site-id">{{ site_id }}</span>
        <span v-if="showParcelId" class="pame-site-id__site-pid">
            <span class="pame-site-id__site-pid-label">SITE_PID:</span>
            <span>{{ site_pid }}</span>
        </span>
    </span>
  </template>
  
  <script>
    export default {
      name: "pame-site-id",
      props: {
         site_id: {
          required: true,
          type: String,
        },
        site_pid: {
          required: true,
          type: String,
        },
      },
  
      computed: {
        showParcelId () {
          return String(this.site_pid) !== String(this.site_id)
        }
      },
  
      methods: {
        
      }
    }
  </script>
  <style lang="css">
  .pame-site-id {
  }
  </style>