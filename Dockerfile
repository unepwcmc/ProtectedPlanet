FROM ruby:2.6.3

ARG user=unepwcmc
ARG group=unepwcmc
ARG gid=1000
ARG uid=1000

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


RUN mkdir /ProtectedPlanet \
    && chown -R 1000:1000 /ProtectedPlanet \
    && groupadd -g ${gid} ${group} && useradd -u ${uid} -g ${group} -d /ProtectedPlanet -s /bin/bash ${user}

USER unepwcmc

WORKDIR /ProtectedPlanet

ADD Gemfile /ProtectedPlanet/Gemfile
ADD Gemfile.lock /ProtectedPlanet/Gemfile.lock
ADD package.json /ProtectedPlanet/package.json
ADD docker/scripts /ProtectedPlanet/docker/scripts

RUN gem install bundler -v 1.17.3 && bundle _1.17.3_ install
RUN yarn install

COPY --chown=${user}:${group} . /ProtectedPlanet

EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
