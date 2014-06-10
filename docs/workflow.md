# Development Workflow, Conventions and Tips

Stolen without guilt from [NRT](https://github.com/unepwcmc/NRT).

### Testing

The application is built test-first, using TDD. New features are expected to have
test coverage. See the [testing README](tests.md) for more info.

### Tabs (nope)

No tabs please, 2 spaces in all languages (HTML, CSS, Ruby, Coffeescript...).

### Line-length

80 characters

### Commit workflow

Work on feature branches, commit often with small commits with only one change
to the code. When you're ready to merge your code into the master branch,
submit a pull request and have someone else review it.

### Commenting your code

Writing small (less than 10 lines), well named functions is preferable to
comments, but obviously comment when your code isn't intuitive.

### Documentation

New developers will be expected to be able to get the application up and
running on their development machines purely by reading the README. Doing
anything in the app workflow which isn't intuitive? Make sure it's in the docs.
