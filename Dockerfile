FROM ubuntu:14.04

FROM ruby:2.1.2
MAINTAINER andrew.potter@unep-wcmc.org

RUN apt-get update && apt-get install -y \
    build-essential \
    nodejs

RUN apt-get purge libgdal1
RUN apt-get install software-properties-common -y
RUN apt-add-repository --remove ppa:ubuntugis/ppa -y

RUN apt-get install libgdal1h -y
RUN apt-get install gdal-bin
RUN apt-get install libproj-dev
RUN apt-get install libspatialite-dev
RUN apt-get install libgeos-c1 --force-yes

RUN echo libgeos-c1 hold | dpkg --set-selections
RUN echo libgdal1 hold | dpkg --set-selections

RUN apt-get install libgdal-dev -y
RUN apt-get install libgdal1-dev -y

COPY Gemfile Gemfile.lock ./
RUN gem install bundler && bundle install

COPY . ./

EXPOSE 3000

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
