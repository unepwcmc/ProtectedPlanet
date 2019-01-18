FROM ubuntu:14.04
MAINTAINER andrew.potter@unep-wcmc.org

RUN apt-get update && apt-get install -y \
    build-essential \
    nodejs \
    curl \
    git

RUN apt-get purge libgdal1
RUN apt-get install software-properties-common -y
RUN apt-add-repository --remove ppa:ubuntugis/ppa -y

RUN apt-get install libgdal1h -y
RUN apt-get install gdal-bin -y

RUN apt-get install libproj-dev -y
RUN apt-get install libspatialite-dev -y
RUN apt-get install libgeos-c1 --force-yes

RUN echo libgeos-c1 hold | dpkg --set-selections
RUN echo libgdal1 hold | dpkg --set-selections

RUN apt-get install libgdal-dev -y
RUN apt-get install libgdal1-dev -y

RUN gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
RUN \curl -L https://get.rvm.io | bash -s stable
RUN /bin/bash -l -c "rvm requirements"
RUN /bin/bash -l -c "rvm install 2.3"
RUN /bin/bash -l -c "gem install bundler --no-ri --no-rdoc"

WORKDIR /ProtectedPlanet
ADD Gemfile /ProtectedPlanet/Gemfile
ADD Gemfile.lock /ProtectedPlanet/Gemfile.lock
RUN /bin/bash -l -c "bundle install"

COPY . /ProtectedPlanet

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]
