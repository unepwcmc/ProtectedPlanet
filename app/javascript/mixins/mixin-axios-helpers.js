import axios from 'axios'

export default {
  methods: {
    axiosSetHeaders () {
      const csrf = document.querySelectorAll('meta[name="csrf-token"]')[0].getAttribute('content')
      console.log(csrf)
      axios.defaults.headers.common['X-CSRF-Token'] = csrf
    }
  }
}