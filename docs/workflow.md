# Development Workflow, Conventions and Tips

### Frontend development
The Protected Planet SCSS code lives in `app/assets/stylesheets` and is compiled via
Sprockets.

The frontend utilises Vue v2.6.10 and Vuex in the Single File Component format
(SFCs) - these reside within `app/javascript/components`, `app/javascript/` more
generally being the folder which holds all of the various other helpers and mixins.
Webpacker takes care of compiling the JavaScript.

Vuex holds stateful client-side information, such as the download keys for the various
downloads, map layers and the filters that have been applied to the PAME table. 

Props for these SFCs are (against convention) piped in directly into the components
from the backend in the various ERB view files.

### Testing

The application is built test-first, using TDD, but only on the backend. New features are 
expected to have test coverage.

At present, there are no front end tests in the application.

UPDATE 16/6/21: Tests will need to be fixed - they have not been working for some 
time now. Consider replacing Minitest with RSpec and rewriting the specs.

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
