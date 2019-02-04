FROM ruby:2.3
MAINTAINER andrew.potter@unep-wcmc.org

RUN apt-get update && apt-get install -y \
    build-essential \
    nodejs \
    curl \
    git

RUN apt-get install software-properties-common -y

WORKDIR /gdal
RUN wget http://download.osgeo.org/gdal/1.11.5/gdal-1.11.5.tar.gz
RUN tar -xvf gdal-1.11.5.tar.gz
RUN cd gdal-1.11.5 \
    && ./configure --prefix=/usr \
    && make \
    && make install

WORKDIR /postgres
RUN wget https://ftp.postgresql.org/pub/source/v11.1/postgresql-11.1.tar.gz
RUN tar -xvf postgresql-11.1.tar.gz
RUN cd postgresql-11.1 \
    && ./configure --prefix=/usr \
    && make \
    && make install

WORKDIR /ProtectedPlanet
ADD Gemfile /ProtectedPlanet/Gemfile
ADD Gemfile.lock /ProtectedPlanet/Gemfile.lock
RUN bundle install

COPY . /ProtectedPlanet

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]
