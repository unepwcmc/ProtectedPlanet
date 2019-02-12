FROM ruby:2.3
MAINTAINER andrew.potter@unep-wcmc.org

RUN apt-get update && apt-get install -y \
    build-essential \
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

WORKDIR /node
RUN wget http://nodejs.org/dist/v10.8.0/node-v10.8.0.tar.gz
RUN tar -xvf node-v10.8.0.tar.gz
RUN ls node-v10.8.0
RUN cd node-v10.8.0 \
    && ./configure --prefix=/usr \
    && make install \
    && wget https://www.npmjs.org/install.sh | sh

RUN whereis npm
RUN npm install bower -g

WORKDIR /ProtectedPlanet
ADD Gemfile /ProtectedPlanet/Gemfile
ADD Gemfile.lock /ProtectedPlanet/Gemfile.lock
RUN bundle install

ARG USER=node
ARG UID=1000
ARG HOME=/home/$USER
RUN adduser --uid $UID --shell /bin/bash --home $HOME $USER

COPY . /ProtectedPlanet

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]
