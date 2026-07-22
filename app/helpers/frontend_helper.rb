# Rails -> Vue "island" mount contract.
#
# Renders a mount point plus a JSON <script> block that the matching Vite
# entrypoint reads with readMountProps() (see app/frontend/lib/readMountProps.ts).
#
# This avoids large data-props="..." attributes (escape bugs, size limits) — see
# upgrade-plan/frontend/14-architecture-and-design.md.
#
# Usage (ERB):
#   <%= frontend_mount "search-areas", props: search_areas_vue_props %>
#
# Renders:
#   <div id="mount-search-areas" data-mount="search-areas"></div>
#   <script type="application/json" id="props-search-areas">{...}</script>
#
# For a component rendered more than once on the same page (e.g. one card per row
# in a loop), pass `key:` so each instance gets its own DOM id / props block while
# still resolving to the same registry entry:
#   <%= frontend_mount "ListingPageCardNews", key: index, props: {...} %>
#
# Renders (data-mount stays the plain registry id; only the DOM/props ids change):
#   <div id="mount-ListingPageCardNews-0" data-mount="ListingPageCardNews" data-props-id="ListingPageCardNews-0"></div>
#   <script type="application/json" id="props-ListingPageCardNews-0">{...}</script>
#
# The Vite entrypoint tag itself is loaded once per page (in the layout head or
# the page's own view) via vite_javascript_tag — keep one entrypoint per page
# type, not per mount.
module FrontendHelper
  # @param name [String, Symbol] mount/registry id, e.g. "search-areas"
  # @param props [Hash] serialised to JSON and read by the entrypoint
  # @param tag [Symbol, String] wrapper element (default :div)
  # @param key [String, Symbol, Integer, nil] disambiguates repeated instances of the same mount id
  # @param html [Hash] extra HTML attributes for the mount element
  def frontend_mount(name, props: {}, tag: :div, key: nil, **html)
    id = name.to_s
    props_id = key.nil? ? id : "#{id}-#{key}"
    mount_attrs = { id: "mount-#{props_id}", data: { mount: id, props_id: props_id } }.deep_merge(html)

    content_tag(tag, "", mount_attrs) +
      content_tag(
        :script,
        raw(json_escape(props.to_json)),
        type: "application/json",
        id: "props-#{props_id}"
      )
  end
end
