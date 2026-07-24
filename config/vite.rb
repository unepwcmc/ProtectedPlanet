# frozen_string_literal: true

require_relative 'application'

# ENVs are for .ts/.vue files. Prefix with VITE_ so vite.config.mts forwards
# them and Vite exposes them to client code via import.meta.env — see
# https://vite-ruby.netlify.app/guide/plugins.html#environment
# If you add any envs here, also add a type to app/frontend/composables/useEnvs.ts
ViteRuby.env['VITE_MAPBOX_TOKEN'] = Rails.application.secrets.mapbox[:access_token]
