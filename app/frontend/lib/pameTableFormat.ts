// Shared by Pame/Table/Row/Index.vue and Pame/Table/Row/Mobile.vue — both render
// the same evaluation item, one as a wide table row, one as a stacked mobile card.

export function trimText(phrase: string | null | undefined, maxLength = 30): string {
  const value = phrase ?? ''
  return value.length <= maxLength ? value : `${value.substring(0, maxLength - 3)}...`
}

// PameEvaluationItem's `country` field is an array (an evaluation can cover
// more than one country) — show the single value, or "Multiple" if there's
// more than one, matching the legacy `checkForMultiples` helper.
export function joinOrMultiple(values: string[]): string {
  return values.length > 1 ? 'Multiple' : trimText(values[0])
}
