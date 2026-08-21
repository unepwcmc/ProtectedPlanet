export function executeAfterCondition(condition: () => boolean, onReady: () => void, maxAttempts = 0): void {
  let attempts = 0

  const interval = window.setInterval(() => {
    attempts++

    if (condition() || (maxAttempts && attempts > maxAttempts)) {
      window.clearInterval(interval)
      onReady()
    }
  }, 200)
}
