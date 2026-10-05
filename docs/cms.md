# CMS

User-generated content — news stories, resources, and most static pages — is
managed with [Comfortable Media Surfer](https://github.com/shakacode/comfortable-media-surfer)
(`comfortable_media_surfer ~> 3.1`, the maintained fork of Comfortable Mexican
Sofa). Admin lives at `/admin`.

## Extensions

We add:

- **Call To Action (CTA)** content, used by the Protected Planet API and Live
  Report banners.
- Extra categorisation for pages and layouts.
- The [banner system](banner_system.md), at `/admin/banners`.

## Monkey patches

Both in `config/initializers/`:

- `comfortable_mexican_sofa.rb` — extends `Seeds::Importer` / `Seeds::Exporter`
  (via metaprogramming) so they carry the `CallToAction` model.
- `comfy_patching.rb` — reopens the Comfy models to add relationships and
  methods, plus importer/exporter changes that reopen existing methods and so
  can't live in the initializer.

The admin stylesheet is the only thing still going through Sprockets, which is
why `sprockets-rails`, `sassc-rails` and `terser` remain in the Gemfile.
