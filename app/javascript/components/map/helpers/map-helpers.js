export const getFirstForegroundLayerId = map => {
  let firstBoundaryId = ''
  let firstSymbolId = ''

  for (const layer of map.getStyle().layers) {
    if (layer.id.match('admin') && layer.id.match('boundary')) {
      firstBoundaryId = layer.id
      break
    } else if (layer.type === 'symbol') {
      firstSymbolId = layer.id
    }
  }

  return firstBoundaryId || firstSymbolId
}