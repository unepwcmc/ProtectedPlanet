import { executeAfterCondition } from '../../../helpers/timing-helpers'

export default {
  data () {
    return {
      firstForegroundLayerId: '',
    }
  },

  methods: {
    setFirstForegroundLayerId () {
      this.firstForegroundLayerId = this.getFirstForegroundLayerId()
    },

    getFirstForegroundLayerId () {
      let firstBoundaryId = ''
      let firstSymbolId = ''
    
      for (const layer of this.map.getStyle().layers) {
        if (layer.id.match('admin') && layer.id.match('boundary')) {
          firstBoundaryId = layer.id
          break
        } else if (layer.type === 'symbol') {
          firstSymbolId = layer.id
        }
      }
    
      return firstBoundaryId || firstSymbolId
    },

    executeAfterStyleLoad (cb) {
      executeAfterCondition(
        () => this.map.isStyleLoaded(), 
        cb
      )
    }
  }
}