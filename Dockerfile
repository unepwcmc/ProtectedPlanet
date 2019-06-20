FROM unepwcmc/unepwcmc-geospatial-base:latest
LABEL maintainer="andrew.potter@unep-wcmc.org"

USER unepwcmc

WORKDIR /ProtectedPlanet
ADD Gemfile /ProtectedPlanet/Gemfile
ADD Gemfile.lock /ProtectedPlanet/Gemfile.lock

RUN /bin/bash -l -c "bundle install"

COPY . /ProtectedPlanet

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]
