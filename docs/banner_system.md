# Banner system

Site-wide dismissible banners, managed in the CMS admin at `/admin/banners`.

## How it works

- `Banner` (`app/models/banner.rb`) — `title` (optional, ≤100 chars),
  `content` (rich text, required), `is_active`. Scope: `Banner.active`.
- `app/views/layouts/partials/_banner.html.erb` renders
  `turbo_mount "Banner", props: { banners:, signature: }` when `banner_visible?`.
- `app/frontend/components/Banner/` — `Index.vue` (carousel, close, cookies) and
  `Content.vue`. Styling is Tailwind in the SFCs.
- `ApplicationHelper#banner_visible?` / `#banner_signature`
  (`app/helpers/application_helper.rb`) decide visibility.
- Admin CRUD: `app/controllers/admin/banners_controller.rb`,
  `app/views/admin/banners/`.

## Dismissal

Cookies, `path=/`, **max-age 2 weeks**:

| Banners active | Cookie | Value |
|---|---|---|
| One | `banner_closed` | the banner's id |
| More than one | `banner_closed_sig` | SHA1 of the active ids, joined by `-` |

So publishing, unpublishing or reordering banners changes the signature and the
group reappears — a user's dismissal only silences the exact set they saw.

## Troubleshooting

Banner not showing? In order: is a banner `is_active`; has the browser got a
matching `banner_closed` / `banner_closed_sig` cookie; any JS errors in the
console.
