FROM ruby:2.6.3

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && wget -qO- https://deb.nodesource.com/setup_12.x | bash \
    && apt-get install -y \
        libgdal-dev \
        libspatialite-dev \
        gdal-bin \
        shared-mime-info \
        build-essential \
        postgresql-client \
        libproj-dev proj-data proj-bin libgeos-dev python-gdal \
        nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && npm install -g yarn


RUN mkdir /ProtectedPlanet
WORKDIR /ProtectedPlanet

ADD Gemfile /ProtectedPlanet/Gemfile
ADD Gemfile.lock /ProtectedPlanet/Gemfile.lock
ADD package.json /ProtectedPlanet/package.json
ADD docker/scripts /ProtectedPlanet/docker/scripts

RUN gem install bundler && bundle install
RUN yarn install

COPY . /ProtectedPlanet

EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
