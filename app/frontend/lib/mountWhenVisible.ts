// Lazy-mount an island only once it scrolls into view — use in a single page's
// entrypoint for below-the-fold maps/charts, NOT as a global loop over widgets.
// See upgrade-plan/frontend/14-architecture-and-design.md (Lazy mount).

export function mountWhenVisible(el: HTMLElement, mount: () => void): void {
  if (!('IntersectionObserver' in window)) {
    mount()
    return
  }
  const io = new IntersectionObserver((entries) => {
    if (entries.some((e) => e.isIntersecting)) {
      mount()
      io.disconnect()
    }
  })
  io.observe(el)
}
