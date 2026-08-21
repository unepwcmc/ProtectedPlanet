// Shared by Pame/Table/Row/{Index,Mobile}.vue, which render the same evaluation
// item as a wide table row and as a stacked mobile card.

export function trimText(phrase: string | null | undefined, maxLength = 30): string {
  const value = phrase ?? ''
  return value.length <= maxLength ? value : `${value.substring(0, maxLength - 3)}...`
}

// `country` is an array, since an evaluation can cover several — show the one
// value, or "Multiple".
export function joinOrMultiple(values: string[]): string {
  return values.length > 1 ? 'Multiple' : trimText(values[0])
}
