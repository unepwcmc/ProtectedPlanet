# Development workflow, conventions and tips

## Frontend

Vue 3 + Vite + Tailwind v4. Webpacker, Vue 2, Vuex and the SCSS asset pipeline
are gone — `app/javascript` no longer exists and there are no `.scss` files left
in `app/`. `sprockets-rails` stays only for `app/assets/images` and the Comfy
admin stylesheet.

- **Components** — Vue 3 SFCs in `app/frontend/components`, Composition API +
  TypeScript throughout.
- **Mounting** — every component is a standalone **island**: its own
  `createApp()` in its own DOM node, not one app owning the page. Views render
  `<%= turbo_mount "<Name>", props: {...} %>` (the `turbo-mount` gem); the
  name → lazy-loader registry is in `app/frontend/entrypoints/application.ts`
  and the wiring in `app/frontend/lib/turboMount.ts`. Props are passed as a Ruby
  hash and arrive as the component's props.
- **Styling** — Tailwind v4 via `@tailwindcss/vite`, entry `app/frontend/styles`,
  loaded as a blocking stylesheet from the `vitecss.css` entrypoint. Every
  font-size/weight combination must route through a shared `tw-shared-font-*`
  utility, never raw `text-*`/`font-*` in markup.
- **Colours** — define as `--color-*` in `styles/tailwind.css`'s `@theme` block
  and reach them through a token. No hex values in components, no
  `bg-[#...]`. Chart colours live there too (`--color-theme-chart-*`); amCharts
  is the one consumer that can't use a class, so `constants/charts.ts` mirrors
  the palette as literals.
- **State** — composables only, no store library. Prefer tree-scoped
  `provide`/`inject` (see `composables/useMapOverlays.ts` for why); reach for
  module-level shared state only when browser storage already owns it, as in
  `useDownloads.ts`.
- **HTTP** — the `fetch` helpers in `app/frontend/lib/http.ts` (`getJson` /
  `postJson`, which handle the CSRF header). There is no `axios`; don't add one.
- **No Turbo Drive.** turbo-mount is Stimulus-based and unrelated to it; every
  navigation is an ordinary full document load. See
  `upgrade-plan/backend/CARRYOVER.md` §8ac.

## Testing

Backend is built test-first with Minitest; new features are expected to have
coverage. Run it against the PG17 test container:

```bash
TEST_POSTGRES_HOST=protectedplanet-db-test bundle exec rails test
```

Frontend: `yarn test` (Vitest, specs in `__tests__` next to the code),
`yarn test:watch`, `yarn typecheck` (vue-tsc), `yarn lint`, `yarn lint:css`.

CI is [`.github/workflows/test.yml`](../.github/workflows/test.yml). It replays
all migrations and runs both suites, but is **deliberately not a required check**
while the Ruby suite is red — see the comment at the top of that file, and
[known-issues.md](known-issues.md).

## Conventions

- Keep lines to 80 characters where you can.
- Feature branches; small, single-purpose commits; PR reviewed by someone else.
- **Changes under `db/`** are commits to the `protectedplanet-db` submodule —
  merge that PR first, then the one in this repo.
- Prefer small, well-named functions over comments; comment the non-obvious.
- New developers should be able to get running from the docs alone. If you did
  something non-obvious, write it down.

## Tips

**See the real error instead of the error page** — uncomment the error handling
and `render_500` section in
[application_controller.rb](/app/controllers/application_controller.rb).

**Silence SQL in the log** so you can see your own output — add
`config/initializers/activerecord_logger.rb` locally (**do not commit it**):

```ruby
ActiveRecord::Base.logger = nil
```
