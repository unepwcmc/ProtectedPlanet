# Development Workflow, Conventions and Tips

### Frontend development

Vue 3 + Vite + Tailwind v4. The Webpacker/Vue 2/Vuex stack and the SCSS asset
pipeline it came with are gone — `app/javascript` no longer exists, and the only
remaining `.scss` file is the Comfy CMS admin override. `sprockets-rails` stays
only to serve `app/assets/images`.

- **Components** — Vue 3 SFCs in `app/frontend/components`, Composition API +
  TypeScript throughout.
- **Mounting** — each component is a standalone "island": its own `createApp()`
  mounted into its own DOM node, not one app owning the page. Views render
  `<%= turbo_mount "<Name>", props: {...} %>` (the `turbo-mount` gem); the
  name → lazy-loader registry lives in `app/frontend/entrypoints/application.ts`
  and the wiring in `app/frontend/lib/turboMount.ts`. Props are passed from the
  ERB as a Ruby hash and arrive as the component's props.
- **Styling** — Tailwind v4 via `@tailwindcss/vite`, entry `app/frontend/styles`,
  loaded as a real blocking stylesheet from the `vitecss.css` entrypoint. Every
  font-size/weight combination must route through a shared
  `tw-shared-font-*` utility rather than raw `text-*`/`font-*` in markup.
- **State** — Pinia (`app/frontend/stores`) only for state that genuinely
  outlives a single component tree (e.g. download keys). Prefer tree-scoped
  `provide`/`inject` composables otherwise — see `composables/useMapOverlays.ts`
  for why.
- **HTTP** — use the `fetch`-based helpers in `app/frontend/lib/http.ts`
  (`getJson`/`postJson`, which handle the CSRF header). There is no `axios`
  dependency any more; don't reintroduce one.
- **No Turbo Drive.** turbo-mount is Stimulus-based and unrelated to it; every
  navigation is an ordinary full document load. See
  `upgrade-plan/backend/CARRYOVER.md` §8ac.

### Testing

The application is built test-first, using TDD, but only on the backend. New features are 
expected to have test coverage.

The frontend has a Vitest suite (`yarn test`, or `yarn test:watch`) covering
components, composables and `lib/` — specs live in `__tests__` directories
alongside the code they cover. Also available: `yarn typecheck` (vue-tsc),
`yarn lint` / `lint:css`.

> **Note**: As of 16/6/21, tests need to be fixed - they have not been working for some 
> time now. Consider replacing Minitest with RSpec and rewriting the specs.

### Line-length

Try to keep your lines 80 characters maximum!

### Commit workflow

Work on feature branches, commit often with small commits with only one change
to the code. When you're ready to merge your code into the develop branch,
submit a pull request and have someone else review it.

If any files are changed within the `db` submodule, you will first need to create a 
PR for your updates in the `protectedplanet-db` repository and merge that in before
any PRs affecting the larger application.

### Commenting your code

Writing small (less than 10 lines), well named functions is preferable to
comments, but obviously comment when your code isn't intuitive.

### Documentation

New developers will be expected to be able to get the application up and
running on their development machines purely by reading the README. Doing
anything in the app workflow which isn't intuitive? Make sure it's in the docs.

# Tips

### Fed up seeing error page rather than actual error?

1. Go to [application_controller.rb](/app/controllers/application_controller.rb)
2. Uncomment the section that has error handling and render_500


### Want to hide DB quries in logs so you can see your -> puts "hello world"
<mark>••• Do not push following to repo! This is only for local development purpose</mark>

1. create a new rb file under /config/initializers    i,e /config/initializers/activerecord_logger.rb
2. add the following lines

    ```ruby
        # The following lines are for not showing db queries in logs
        old_logger = ActiveRecord::Base.logger
        ActiveRecord::Base.logger = nil
    ```
