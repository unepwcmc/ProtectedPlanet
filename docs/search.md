# Search

The Protected Planet search feature is powered by
[Elasticsearch](http://www.elasticsearch.org/overview/elasticsearch/).

## How it works

[Official docs](https://www.elastic.co/guide/en/elastic-stack-get-started/current/get-started-elastic-stack.html)

Elasticsearch operates effectively as a JSON document store, that is
accessed by a JSON [query
DSL](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl.html).
Documents (protected areas, countries and regions) are converted to JSON
and saved in Elasticsearch as an index for querying.

The application does not hook in to Elasticsearch in any magic ways, and
nor does Elasticsearch hook in to the application. Queries are passed
over http to Elasticsearch, and results parsed in to ActiveRecord models
by the application. We *do* utilise the elasticsearch gem, and that is effectively 
the Ruby wrapper for the Elasticsearch service, allowing us to use the same DSL.
More information can be found in the [Github repo for the gem](https://github.com/elastic/elasticsearch-ruby)

## Installation

Thankfully, Elasticsearch installation is super easy.

On OS X:

```
brew update
brew install elasticsearch
```

On Ubuntu/Debian systems, the
[process](https://gist.github.com/wingdspur/2026107) is longer but still
easy.

### Production

Production installation is, as with everything, handled by the [Ansible
scripts](servers.md) and **should not be done manually**.

Elasticsearch is optimised for quick development, and as such it has
pretty poor defaults for production, such as small allocations of
memory. The [Ansible scripts](servers.md) handle setting these up for
you, but for more info check out the [pre-flight
checklist](http://www.elasticsearch.org/webinars/elasticsearch-pre-flight-checklist/).

## Indexing

As the indexed materials (PAs, countries, regions) are only
modified during an import, there are no triggers or automatic methods of
re-indexing the search. It is, however, a simple and (kind of) quick
process.

Elasticsearch is a JSON document store, and so to create an index, we
convert the desired models in to JSON objects and PUT them in to the
chosen index. In our case, we are using a single index to store multiple
models: Protected Areas, Countries, and Regions. This way only a single,
simple query needs to be made and multiple models can be interleaved in
results.

Documents are stored with their `_type` set to the name of the converted
Model, so that they can be converted back to ActiveRecord objects on
retrieval.

Indexing is handled by `Search::Index` automatically at the end of an
import, but can be run manually:

```
bundle exec rake search:reindex
```

## Querying

The `Search` class acts as a neat wrapper for hiding the terrifying
complexity that is building Elasticsearch JSON queries:

```
# Basic search
Search.search 'manbone'

# Search with filters
Search.search 'manbone', filters: {type: 'country', country: 123}

# Search with pagination
Search.search 'manbone', page: 3
```

Various other utility classes can be found within `lib/modules/search`, namely
the sorters and the matchers, which allows them to be easily extensible.

### Troubleshooting

* You may have to rebuild the search indices on staging/production on occasion: 

Run this in the console:

```
  RAILS_ENV=<environment> bundle exec rake search:reindex
```

### Elasticsearch implementation in Protected Planet

methods/files that need changing to add/modify filtering:
- `#as_indexed_json`: this is the method that creates the json that is stored and queried in elasticsearch. if it's not in here, it can't be queried.
- `search.yml`: Adds configuration details for each search field. Currently, fields can be boolean (see note below), nested, or geo. The type is used to select the right processing class in the search/ namespace. With nested filters you need to also specify the required param, or by default a NOT filter will be applied.
- `modules/search.rb`: modify ALLOWED_FILTERS
- `search/filter_params.rb`: processes the params before submission to elasticsearch. Nested search types don't need processing, but boolean usually do (see note below)
- `aggregations.json`: used in the aggregation.rb to support elasticsearch aggregations (is this being used?)
- `mappings.json`: used to create search indexes in elasticsearch, so new/modified search attributes should be added here
- `search/filters_serializer.rb`: creates the filter options displayed in the front end, and the params they submit

##### Boolean vs nested filters

The boolean and nested filters are combined to form the final elasticsearch query. The filters are grouped under their 'name' like this:

```
{
  boolean_field_1: [boolean_filter_1a AND boolean_filter_1b AND boolean_filter_1c]
} AND {
  boolean_field_2: [boolean_filter_2a AND boolean_filter_2b AND boolean_filter_2c]
} AND {
  nested_field_1: [nested_filter_1a OR nested_filter_1b OR nested_filter_1c]
} AND {
  nested_field_2: [nested_filter_2a OR nested_filter_2b OR nested_filter_2c]  
}
```

***However*** Because of the way the filters are set up in the UI, boolean filters appear to be processed as OR statements. They are not, we delete some of the filters on the back end to make it appear this way. If a user selects WDPA and OECM, if we submitted both of those parameters we would get zero results, because a Protected Area can't be both of them. so in the back end we delete the filters if both are submitted. same for Type. This works ok, because both categories are binary, and the WDPA/OECM and Marine/Terrestrial categories aren't mutually exclusive. If you have a filter that isn't binary, e.g. Green Listed, Green List Candidate, and Neither, we can't use this method.

However, with Elasticsearch we can convert these binary values into nested values to make groups of non-exclusive binary options (see ProtectedArea#as_indexed_json and #special_status).
