# Development Workflow, Conventions and Tips

### Frontend development

The Protected Planet CSS code lives in the
[protectedplanet-frontend](https://github.com/unepwcmc/protectedplanet-frontend)
repository. When installing Protected Planet, the rake command `rake bower:install`
downloads and extract the frontend into
`vendor/assets/bower_components/protectedplanet-frontend`. While this is awesome in
staging/production, it's a bummer on development, as all changes to the frontend code
will be discarded.

To solve this issue, after running `rake bower:install` in your PP repository,
clone the `protectedplanet-frontend` repository somewhere else
on your machine, and symlink it to your vendor folder. Like this:

```bash
$ cd ..

$ git clone git@github.com:unepwcmc/protectedplanet-frontend.git
# follow the installation steps in the protectedplanet-frontend README

$ cd ProtectedPlanet/vendor/assets/bower_components
$ rm -rf protectedplanet-frontend # remove the bower-installed package

# the first argument HAS to be an absolute path, you can't do relative paths
$ ln -s /Users/you/projects/protectedplanet-frontend protectedplanet-frontend
```

Now you can edit the frontend code in the protectedplanet-frontend folder, and it
will be immediately reflected in the development website.

For more information on how to write and commit frontend code, check the
[protectedplanet-frontend README](https://github.com/unepwcmc/protectedplanet-frontend).

### Testing

The application is built test-first, using TDD. New features are expected to have
test coverage.

### Tabs (nope)

No tabs please, 2 spaces in all languages (HTML, CSS, Ruby, Coffeescript...).

### Line-length

100 (but try to keep it below 80) characters

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
