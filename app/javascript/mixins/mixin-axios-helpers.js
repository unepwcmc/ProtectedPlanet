import { setAxiosHeaders } from '../helpers/axios-helpers'
import axios from 'axios'

export default {
  methods: {
    axiosSetHeaders () {
      setAxiosHeaders(axios)
    }
  }
}