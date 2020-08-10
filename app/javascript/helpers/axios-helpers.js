export const setAxiosHeaders = axios => {
  const token = document.head.querySelector('meta[name="csrf-token"]')

  if (token) {
    axios.defaults.headers.common['X-CSRF-Token'] = token.content
  } else {
    console.error('CSRF token not found')
  }
}