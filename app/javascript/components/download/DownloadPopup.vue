<template>
  <div class="popup--download">
    <ul class="popup__ul">
      <li 
        v-for="option in options"
      >
        <span class="popup__link" v-html="option.title"></span>
      </li>
    </ul>
  </div>
</template>
<script>
export default {
  name: 'download-popup',

  props: {
    options: Array
  }
}
</script>