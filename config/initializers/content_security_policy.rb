# Sent as a real response header rather than a <meta http-equiv> tag: a meta
# policy only governs the markup that follows it (so the JSON-LD block in
# layouts/partials/_head.html.erb escaped it) and browsers ignore header-only
# directives such as frame-ancestors and report-uri in meta.
#
# Skipped in development, where the Vite dev server needs inline/eval'd code
# and a websocket back to its own origin.
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.script_src  :self, 'https://www.googletagmanager.com', 'https://*.hotjar.com', 'https://*.hotjar.io'
    policy.style_src   :self, :unsafe_inline
    policy.img_src     :self, :data, :blob, :https
    policy.font_src    :self, :data
    policy.connect_src :self, :https
    policy.frame_src   'https://*.hotjar.com'
    policy.object_src  :none
    policy.base_uri    :self
    policy.upgrade_insecure_requests
  end
end
