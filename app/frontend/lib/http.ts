// Vue3 replacement for app/javascript/helpers/axios-helpers.js — same CSRF
// header contract, backed by native fetch instead of axios.
function csrfToken(): string {
  const token = document.head.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')

  if (!token) {
    console.error('CSRF token not found')
    return ''
  }

  return token.content
}

async function parseJsonResponse<T>(response: Response): Promise<T> {
  if (!response.ok) {
    throw new Error(`Request failed with status ${response.status}`)
  }

  return response.json() as Promise<T>
}

export function postJson<T>(url: string, body?: unknown): Promise<T> {
  return fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrfToken()
    },
    body: JSON.stringify(body ?? {})
  }).then(parseJsonResponse<T>)
}

export function getJson<T>(url: string, params?: Record<string, string> | URLSearchParams): Promise<T> {
  const query = params ? `?${new URLSearchParams(params).toString()}` : ''

  return fetch(`${url}${query}`, {
    headers: { 'X-CSRF-Token': csrfToken() }
  }).then(parseJsonResponse<T>)
}
