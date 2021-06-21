# CMS

## Comfortable Mexican Sofa

We use Comfortable Mexican Sofa (v2.0.0) to manage our user-generated content, i.e.
the news stories and resources that are created monthly by CLS detailing updates to
the WDPA and other noteworthy items. 

On its own, it is literally just a tool to manage content, but we have made a few
extensions to it for our own purposes.

These comprise the Call To Action (CTA) content for the Protected Planet API and 
Protected Planet Live Report banners as well as extra categorisation for pages and layouts.

### Seeds

Within the `db` submodule/folder there is a folder called `cms_seeds` which contains
all of the pages, files and other content, in HTML format, that has been dumped from the database. This 
is not 100% up to date and likely will never be, because of frequent changes to the content
on production, in particular with respect to the News and Resources sections.

It is this folder that the `rake 'comfy:cms_seeds:import` task looks in for the 
seed files, so it is important that you make sure the name of the folder is passed
correctly as the first argument to the Rake task, whilst the second argument is
the name of the Comfy::Cms::Site you are restoring to.

### Monkey patches

Monkey patches are contained within `config/initializers/comfortable_mexican_sofa.rb`
and `comfy_patching.rb` within the same folder. 

The former contains modifications to the Seeds::Importer and Seeds::Exporter 
classes to enable them to import and export the CallToAction model mentioned 
previously via metaprogramming. 

The latter contains relationships and methods that are passed to the Comfy models by 
reopening them, as well as further changes to the Importer and Exporter that cannot
be adequately inserted into the `comfortable_mexican_sofa` initializer, as they
reopen existing methods and insert extra code into them.

