// Reads props emitted by the `frontend_mount` Rails helper.
// See app/helpers/frontend_helper.rb and
// upgrade-plan/frontend/14-architecture-and-design.md.

/**
 * Read and parse the JSON props block for a mount id.
 * Returns `fallback` when the block is absent (mount not on this page).
 */
export function readMountProps<T = Record<string, unknown>>(
  id: string,
  fallback: T | null = null
): T | null {
  const el = document.getElementById(`props-${id}`)
  if (!el?.textContent) return fallback
  try {
    return JSON.parse(el.textContent) as T
  }
  catch (err) {
    console.error(`[frontend_mount] invalid JSON for props-${id}`, err)
    return fallback
  }
}

/** The DOM element a `frontend_mount` island should mount into. */
export function mountEl(id: string): HTMLElement | null {
  return document.getElementById(`mount-${id}`)
}
