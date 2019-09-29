FROM unepwcmc/unepwcmc-geospatial-base:20190809
LABEL maintainer="andrew.potter@unep-wcmc.org"

USER unepwcmc

WORKDIR /ProtectedPlanet
ADD Gemfile /ProtectedPlanet/Gemfile
ADD Gemfile.lock /ProtectedPlanet/Gemfile.lock
ADD package.json /ProtectedPlanet/package.json
ADD docker/scripts /ProtectedPlanet/docker/scripts

COPY --chown=unepwcmc:unepwcmc . /ProtectedPlanet

ARG NODE_ENV
ARG RAILS_ENV
ENV NODE_ENV $NODE_ENV
ENV RAILS_ENV $RAILS_ENV

RUN /bin/bash -l -c "bundle install"
RUN /bin/bash -l -c "yarn install"

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]
