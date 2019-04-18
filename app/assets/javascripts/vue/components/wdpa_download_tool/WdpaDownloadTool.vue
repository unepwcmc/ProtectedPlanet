<template>
  <div class="flex flex-v-start flex-wrap">
    <v-select-searchable 
      :options="selectOptions"
      :config="selectConfig"
      v-on:update:selected-option="setDownloadUrl"></v-select-searchable>
    <a :class="['wdpa-download-tool__link', { 'button--disabled': !downloadUrl}]" title='Download historic WDPA release' :href='downloadUrl' download>Download WDPA</a>
  </div>
</template>

<script>
module.exports = {
  name: 'wdpa-download-tool',

  components: {
    'v-select-searchable': VComponents['vue/components/v_select_searchable/VSelectSearchable'],
  },

  props: {
    selectOptions: Array,
  },

  data: function () {
    return {
      downloadUrl: '',
      selectConfig: {id: 'wdpa-download-tool-select'}
    }
  },

  methods: {
    setDownloadUrl: function (selectedOption) {
      this.downloadUrl = selectedOption.url
    }
  }
}
</script>
