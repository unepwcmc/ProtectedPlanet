# Background workers

[Sidekiq](https://sidekiq.org) 7, backed by Redis. Config: `config/sidekiq.yml`.

```bash
bundle exec sidekiq -C config/sidekiq.yml
```

## Queues

| Queue | Concurrency | Work |
|---|---|---|
| `default` | 20 (prod/staging), 5 local | Everything except PDFs |
| `pdf` (capsule) | 5 | Country/region PDF factsheets |

`pdf` is a separate Sidekiq capsule because each job drives a page in the shared
headless Chrome — see [pdf-shared-chrome.md](pdf-shared-chrome.md). Its
concurrency caps concurrent *pages*, not browsers, and is kept low because the
map renders through software WebGL and runs out of CPU before memory.

## Workers

`app/workers/download_workers/` — `general`, `search`, `protected_area`, `pdf`,
all on `base.rb`. See [downloads.md](downloads.md).

## Monitoring

Sidekiq Web is mounted at `/admin/sidekiq`. Credentials are in the WCMC
Informatics password database.
