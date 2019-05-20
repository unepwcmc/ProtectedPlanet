FROM gentoo/stage3-amd64
LABEL maintainer="andrew.potter@unep-wcmc.org"

RUN emerge --sync && emerge sudo
RUN emerge dev-vcs/git

WORKDIR /gdal
RUN wget http://download.osgeo.org/gdal/2.4.0/gdal-2.4.0.tar.gz
RUN tar -xvf gdal-2.4.0.tar.gz
RUN cd gdal-2.4.0 \
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
RUN npm install bower yarn -g

WORKDIR /geos
RUN wget https://download.osgeo.org/geos/geos-3.7.0.tar.bz2
RUN tar -xvf geos-3.7.0.tar.bz2
RUN ls geos-3.7.0
RUN cd geos-3.7.0 \
    && ./configure --prefix=/usr \
    && make install

ARG USER=protectedplanet
ARG UID=1000
ARG HOME=/home/$USER
RUN useradd --uid $UID --shell /bin/bash --home $HOME $USER

WORKDIR /rvm
RUN curl -sSL https://github.com/rvm/rvm/tarball/stable -o rvm-stable.tar.gz
RUN mkdir rvm && cd rvm \
    && tar --strip-components=1 -xzf ../rvm-stable.tar.gz \
    && ./install --auto-dotfiles

RUN /bin/bash -l -c ". /home/$USER/.rvm/scripts/rvm"
RUN /bin/bash -l -c "rvm install 2.4.1"

RUN /bin/bash -l -c "gem install bundler"
RUN /bin/bash -l -c "gem install rake"
RUN /bin/bash -l -c "gem install rgeo --version '=0.4.0'" -- --with-geos-dir=/usr/lib


WORKDIR /ProtectedPlanet
ADD Gemfile /ProtectedPlanet/Gemfile
ADD Gemfile.lock /ProtectedPlanet/Gemfile.lock

ADD package.json /ProtectedPlanet/package.json

RUN /bin/bash -l -c "bundle install"
RUN /bin/bash -l -c "yarn install"

COPY . /ProtectedPlanet

RUN chown -R protectedplanet:protectedplanet /home/protectedplanet/.rvm
RUN chown -R protectedplanet:protectedplanet /home/protectedplanet/.bundle

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]
