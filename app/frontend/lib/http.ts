// Shared fetch wrappers, applying the app's CSRF header contract.
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

export interface BlobDownload {
  filename: string
  blob: Blob
}

// For endpoints returning a file (e.g. CSV export) rather than JSON — reads the
// filename back out of Content-Disposition.
export async function postBlob(url: string, body?: unknown): Promise<BlobDownload> {
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrfToken()
    },
    body: JSON.stringify(body ?? {})
  })

  if (!response.ok) {
    throw new Error(`Request failed with status ${response.status}`)
  }

  const disposition = response.headers.get('content-disposition') ?? ''
  const match = disposition.match(/filename="?([^"]+)"?/)

  return { filename: match ? match[1] : 'download.csv', blob: await response.blob() }
}

// For external (non-Rails) hosts, e.g. the ArcGIS point-query services —
// sending our CSRF header there fails their CORS preflight.
export function getJsonExternal<T>(url: string, params?: Record<string, string> | URLSearchParams): Promise<T> {
  const query = params ? `?${new URLSearchParams(params).toString()}` : ''

  return fetch(`${url}${query}`).then(parseJsonResponse<T>)
}
