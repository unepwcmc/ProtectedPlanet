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
# The Vite entrypoint tag itself is loaded once per page (in the layout head or
# the page's own view) via vite_javascript_tag — keep one entrypoint per page
# type, not per mount.
module FrontendHelper
  # @param name [String, Symbol] mount id, e.g. "search-areas"
  # @param props [Hash] serialised to JSON and read by the entrypoint
  # @param tag [Symbol, String] wrapper element (default :div)
  # @param html [Hash] extra HTML attributes for the mount element
  def frontend_mount(name, props: {}, tag: :div, **html)
    id = name.to_s
    mount_attrs = { id: "mount-#{id}", data: { mount: id } }.deep_merge(html)

    content_tag(tag, "", mount_attrs) +
      content_tag(
        :script,
        raw(json_escape(props.to_json)),
        type: "application/json",
        id: "props-#{id}"
      )
  end
end
