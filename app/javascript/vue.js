import Vue from 'vue/dist/vue.esm'

document.addEventListener('DOMContentLoaded', () => { 
  if(document.getElementById('v-app')) {

    const app = new Vue({
      el: '#v-app'
    })
  }
})