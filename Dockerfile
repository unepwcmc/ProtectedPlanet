FROM ruby:2.6.3

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && wget -qO- https://deb.nodesource.com/setup_12.x | bash \
    && apt-get install -y \
        libgdal-dev \
        libspatialite-dev \
        shared-mime-info \
        build-essential \
        postgresql-client \
        nodejs \
        zip \
    && wget --no-check-certificate https://download.osgeo.org/gdal/2.2.3/gdal-2.2.3.tar.gz -O - | tar -xz \
    && wget https://github.com/Esri/file-geodatabase-api/raw/master/FileGDB_API_1.5.2/FileGDB_API-RHEL7-64gcc83.tar.gz -O - | tar -xz \
    && cp ./FileGDB_API-RHEL7-64gcc83/lib/libfgdbunixrtl.a ./FileGDB_API-RHEL7-64gcc83/lib/libfgdbunixrtl.so ./FileGDB_API-RHEL7-64gcc83/lib/libFileGDBAPI.so /usr/local/lib \
    && cp -a ./FileGDB_API-RHEL7-64gcc83/include/. /usr/local/include \
    && cd ./gdal-2.2.3 && ./configure \
        --prefix=/usr \
        --with-fgdb=/usr/local \
        --with-geos \
        --with-geotiff=internal \
        --with-hide-internal-symbols \
        --with-libtiff=internal \
        --with-libz=internal \
        --with-threads \
        --without-bsb \
        --without-cfitsio \
        --without-cryptopp \
        --without-curl \
        --without-dwgdirect \
        --without-ecw \
        --without-expat \
        --without-fme \
        --without-freexl \
        --without-gif \
        --without-gif \
        --without-gnm \
        --without-grass \
        --without-grib \
        --without-hdf4 \
        --without-hdf5 \
        --without-idb \
        --without-ingres \
        --without-jasper \
        --without-jp2mrsid \
        --without-jpeg \
        --without-kakadu \
        --without-libgrass \
        --without-libkml \
        --without-libtool \
        --without-mrf \
        --without-mrsid \
        --without-mysql \
        --without-netcdf \
        --without-odbc \
        --without-ogdi \
        --without-openjpeg \
        --without-pcidsk \
        --without-pcraster \
        --without-pcre \
        --without-perl \
        --with-pg \
        --without-php \
        --without-png \
        --without-python \
        --without-qhull \
        --without-sde \
        --without-sqlite3 \
        --without-webp \
        --without-xerces \
        --without-xml2 \
    && make && make install \
    && ldconfig \
    && apt-get install -y libproj-dev proj-data proj-bin libgeos-dev python-gdal \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && npm install -g yarn

RUN mkdir /ProtectedPlanet
WORKDIR /ProtectedPlanet

ADD Gemfile /ProtectedPlanet/Gemfile
ADD Gemfile.lock /ProtectedPlanet/Gemfile.lock
ADD package.json /ProtectedPlanet/package.json
ADD yarn.lock /ProtectedPlanet/yarn.lock
ADD docker/scripts /ProtectedPlanet/docker/scripts

RUN gem install bundler -v 1.17.3 && bundle _1.17.3_ install
RUN yarn install
# If you are running on Mac OS X, make sure you have this line enabled and comment out RUN yan install above
# RUN export PUPPETEER_SKIP_DOWNLOAD=true && yarn install

COPY . /ProtectedPlanet

EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
