# Search

The Protected Planet search feature is powered by [PostgreSQL Full Text
Search](http://www.postgresql.org/docs/9.3/static/textsearch-intro.html).
It's wicked fast, if I do say so myself.

## How it works

There's a simple guide
[available](http://blog.lostpropertyhq.com/postgres-full-text-search-is-good-enough/),
but it's pretty straightforward.

Full text search operates on 'documents' consisting of the attributes
you want to search through converted in to
[`tsvector`](http://www.postgresql.org/docs/9.3/static/datatype-textsearch.html)s
and concatenated together. The documents are stored in the [materialized
view](http://www.postgresql.org/docs/9.3/static/rules-materializedviews.html)
`tsvector_search_documents`.

The [migration](../db/migrate/20140612133146_add_search_view.rb) shows
how the materialized view is constructed.

### Indexing

The `tsvector` document view is not technically an index, and we will
need to index that view separately. We use
[GIN](http://www.postgresql.org/docs/9.3/static/textsearch-indexes.html)
indexes as they are super fast given our large, static dataset.

```
CREATE INDEX idx_search_documents ON tsvector_search_documents USING gin(document);
```

**The setup for the view and the index is handled by migrations, you do
not need to do anything.**

### Querying

Queries are converted in to `tsquery` types so that they can be compared
to `tsvector`s. Full text search uses the match operator (`@@`) to
compare `tsvector` and `tsquery`.

For example, the following query returns the Protected Area ID (not the
WDPA ID) for any PAs matching 'manbone'.

```
SELECT id
FROM tsvector_search_documents
WHERE document @@ to_tsquery('manbone');
```

Adding a `:*` at the end of search terms will make sure subterms are found as
well. Being `Geoff:*` the search term of the previous query, the `@@` operator
will yield `Geoffery` as a result.

### Handling misspellings

Along the table containing all documents to query against, a second table
(`search_lexemes`), containing all the search lexemes, makes it possible to
have a fuzzy search in protectedplanet.

This is achieved by using the Postgres extension
[`pg_trgm`](http://www.postgresql.org/docs/9.3/static/pgtrgm.html) to match
similar lexemes against the given search term, with a similarity index, ranging
from 0 to 1 (with a default similarity threshold of 0.3).

For example, the following query returns all similar words (and the
corresponding similarity) to `manbone`.

```
SELECT word, similarity(word, 'manbone') AS similarity
FROM search_lexemes
WHERE word % 'manbone'
ORDER BY similarity DESC;
```

The `ORDER BY` clause guarantees having the closest match as first result,
ready to be used as a suitable replacement for a term returning zero search
results.

## Rebuilding

As the indexed materials (PAs, countries, sub locations) are only
modified during an import, there are no triggers or automatic methods of
re-indexing the search. It is, however, a simple and (relatively) quick
process.

Postgres provides a `REFRESH` function for repopulating (deleting and
regenerating) materialized views:

```
REFRESH MATERIALIZED VIEW tsvector_search_documents;
```

There is a rake task available for reindexing:

```
bundle exec rake search:reindex
```
