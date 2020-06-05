FROM ruby:2.6

LABEL maintainer="jonathan.feist@unep-wcmc.org"

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /var/www
ENV RAILS_ENV production

# Add Gemfile stuff first as a build optimization
# This way the `bundle install` is only run when either Gemfile or Gemfile.lock is changed
# This is because `bundle install` can take a long time
# Without this optimization `bundle install` would run if _any_ file is changed within the project, no bueno
ADD Gemfile /opt/myapp/
ADD Gemfile.lock /opt/myapp/
RUN bundle install

# This will now install anything in Gemfile.tip
# This way you can add new gems without rebuilding _everything_ to add 1 gem
# Anything that was already installed from the main Gemfile will be re-used
ADD Gemfile.tip /opt/myapp/
RUN bundle install


COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0", "-p", "3000"]
