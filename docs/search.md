# Search

> 🔴 **Search currently 500s in every environment** — `AppSecrets.elasticsearch.url`
> is dot access on a plain Hash. See [known-issues.md](known-issues.md).

Powered by [Elasticsearch](https://www.elastic.co). Protected areas, countries
and regions are serialised to JSON and stored in a **single index**, so one
query returns interleaved results across all three. Documents carry the model
name so they can be turned back into ActiveRecord objects on retrieval.

Nothing hooks in automatically: queries go over HTTP and the app parses the
results. The `elasticsearch` gem is just the Ruby wrapper for the same DSL.

## Running it

Locally Elasticsearch is the `elasticsearch` container (`:9200`) — nothing to
install. On staging/production it is a Kamal accessory in `config/deploy.yml`
and **should not be configured by hand**; ES ships development-tuned defaults
(small memory allocations) and the accessory config sets the production ones.

We are on the **7.17 client against a 7.17 server**. Don't bump to the 8.x gem —
it is a client rewrite (elastic-transport, namespace changes) and the code uses
`Elasticsearch::Transport::Transport::Errors::*`, which 8.x drops.

## Indexing

Indexed data only changes during a release, so there are no triggers or
automatic reindexing. `Search::Index` runs at the end of an import; manually:

```bash
bundle exec rake search:reindex          # or RAILS_ENV=<env> bundle exec rake search:reindex
```

You may need to rebuild the indices on staging/production occasionally.

## Querying

`Search` wraps the query building:

```ruby
Search.search 'manbone'
Search.search 'manbone', filters: { type: 'country', country: 123 }
Search.search 'manbone', page: 3
```

Sorters and matchers live in `lib/modules/search/` and are extensible.

## Adding or changing a filter

Every one of these needs touching:

| File | Role |
|---|---|
| `ProtectedArea#as_indexed_json` | Builds the stored document. **Not in here, not queryable.** |
| `search.yml` | Per-field config: `boolean`, `nested` or `geo`. Type picks the processing class in `search/`. Nested filters must declare their required param, or a NOT filter is applied by default. |
| `modules/search.rb` | `ALLOWED_FILTERS` |
| `search/filter_params.rb` | Pre-submission param processing. Nested types need none; booleans usually do. |
| `mappings.json` | Index mappings |
| `search/filters_serializer.rb` | The filter options the frontend renders, and the params they submit |
| `aggregations.json` | Used by `aggregation.rb` (possibly unused) |

## Boolean vs nested filters

The final query groups filters by name:

```
{ boolean_field_1: [1a AND 1b AND 1c] }
  AND { boolean_field_2: [2a AND 2b] }
  AND { nested_field_1:  [1a OR 1b OR 1c] }
```

**Boolean filters look like OR in the UI but aren't.** A protected area can't be
both WDPA and OECM, so submitting both would return zero results — instead the
backend *deletes* both filters when both are selected. Same for Marine /
Terrestrial. This works only because those categories are binary and the two
groups aren't mutually exclusive.

It breaks for anything non-binary (Green Listed / Candidate / Neither). Those
have to become nested values instead — see `ProtectedArea#as_indexed_json` and
`#special_status`.
