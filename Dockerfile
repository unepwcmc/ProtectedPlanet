FROM ruby:2.6.3

LABEL maintainer="jonathan.feist@unep-wcmc.org"

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /opt/www
ENV RAILS_ENV development

# Add Gemfile stuff first as a build optimization
# This way the `bundle install` is only run when either Gemfile or Gemfile.lock is changed
# This is because `bundle install` can take a long time
# Without this optimization `bundle install` would run if _any_ file is changed within the project, no bueno
COPY Gemfile /opt/www/
COPY Gemfile.lock /opt/www/
RUN gem install bundler -v 1.17.3 && bundle _1.17.3_ install

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && wget -qO- https://deb.nodesource.com/setup_10.x | bash \
    && apt-get install -y \
        libgdal-dev \
        nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && npm install -g yarn

# This will now install anything in Gemfile.tip
# This way you can add new gems without rebuilding _everything_ to add 1 gem
# Anything that was already installed from the main Gemfile will be re-used
COPY Gemfile.tip /opt/www/
RUN bundle _1.17.3_ install

COPY . .

RUN yarn

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]
