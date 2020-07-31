export const executeAfterCondition = (conditonCb, successCb, maxAttempts=0) => {
  let attempts = 0

  const interval = setInterval(() => {
    attempts++

    if (
      conditonCb() || 
      (maxAttempts && attempts > maxAttempts)
    ) {
      clearInterval(interval)
      successCb()
    }
  }, 200)
}