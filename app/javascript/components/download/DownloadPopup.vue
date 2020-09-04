<template>
  <div class="popup--download">
    <ul class="popup__ul">
      <li 
        v-for="option in options"
        :key="option._uid"
      >
        <span
          v-if="option.isDownload" 
          class="popup__link" 
          @click="clickOption(option)"
          v-html="option.title"
        />
        <a
          v-else
          class="popup__link"
          :href="option.url"
          target="_blank"
          :title="option.title"
          v-html="option.title"
        />
      </li>
    </ul>
  </div>
</template>
<script>
export default {
  name: 'download-popup',

  props: {
    options: Array
  },

  methods: {
    clickOption (option) {
      this.$emit('click:download:option', option)
    }
  }
}
</script>