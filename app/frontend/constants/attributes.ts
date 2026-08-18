// Matches ProtectedAreasHelper::URL_PARAMS[:parcel] ('site_pid').
export const PARCEL_ID_PARAM = 'site_pid'

// Payload-less window custom event dispatched by useParcelSelection whenever
// the site_pid URL param changes, so every other PA-show attributes island
// knows to re-read it.
export const PARCEL_SELECTED_EVENT = 'protectedplanet:parcel-selected'
