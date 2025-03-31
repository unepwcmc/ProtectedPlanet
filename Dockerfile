FROM ruby:2.6.3

RUN DEBIAN_FRONTEND=noninteractive apt-get update
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -
RUN curl -fsSL https://deb.nodesource.com/setup_12.x | bash - && apt-get install --yes nodejs
RUN apt-get install -y \
        apt-utils \
        libgdal-dev \
        libspatialite-dev \
        shared-mime-info \
        build-essential
RUN apt-get install -y postgresql postgresql-client
RUN apt-get install -y zip

# To install dependecies for puppeteer to generate pdfs
RUN apt-get update && apt-get install -y chromium


# for sassc specifically
RUN apt-get install -y \
    g++ \
    make \
    libsass1 \
    libsass-dev
RUN apt-get update && apt-get install -y gdal-bin libgdal-dev libproj-dev proj-data proj-bin libgeos-dev python-gdal
RUN wget --no-check-certificate https://download.osgeo.org/gdal/2.2.3/gdal-2.2.3.tar.gz -O - | tar -xz 
RUN wget https://github.com/Esri/file-geodatabase-api/raw/master/FileGDB_API_1.5.2/FileGDB_API-RHEL7-64gcc83.tar.gz -O - | tar -xz 
RUN cp ./FileGDB_API-RHEL7-64gcc83/lib/libfgdbunixrtl.a ./FileGDB_API-RHEL7-64gcc83/lib/libfgdbunixrtl.so ./FileGDB_API-RHEL7-64gcc83/lib/libFileGDBAPI.so /usr/local/lib  \
    && cp -a ./FileGDB_API-RHEL7-64gcc83/include/. /usr/local/include
RUN cd ./gdal-2.2.3 && ./configure \
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
&& make && make install && ldconfig


# RUN wget https://github.com/Esri/file-geodatabase-api/raw/master/FileGDB_API_1.5.2/FileGDB_API-RHEL7-64gcc83.tar.gz -O - | tar -xz 
# RUN cp ./FileGDB_API-RHEL7-64gcc83/lib/libfgdbunixrtl.a ./FileGDB_API-RHEL7-64gcc83/lib/libfgdbunixrtl.so ./FileGDB_API-RHEL7-64gcc83/lib/libFileGDBAPI.so /usr/local/lib  \
#     && cp -a ./FileGDB_API-RHEL7-64gcc83/include/. /usr/local/include
RUN apt-get clean && rm -rf /var/lib/apt/lists/*
RUN npm install -g yarn

RUN mkdir /ProtectedPlanet
WORKDIR /ProtectedPlanet

ADD Gemfile /ProtectedPlanet/Gemfile
ADD Gemfile.lock /ProtectedPlanet/Gemfile.lock
ADD package.json /ProtectedPlanet/package.json
ADD yarn.lock /ProtectedPlanet/yarn.lock
ADD docker/scripts /ProtectedPlanet/docker/scripts

# We need the following to avoid bundler install error
# https://nokogiri.org/tutorials/installing_nokogiri.html#installing-using-standard-system-libraries
RUN bundle config build.nokogiri --use-system-libraries
RUN gem install bundler -v 1.17.3 && bundle _1.17.3_ install

# if you see Failed to set up Chromium r782078! it is likely becasue you are running from a mac
# https://stackoverflow.com/questions/63187371/puppeteer-is-not-able-to-install-error-failed-to-set-up-chromium-r782078-set
# if so use second line that has PUPPETEER_SKIP_DOWNLOAD=true to run yarn install.
RUN yarn install
# RUN export PUPPETEER_SKIP_DOWNLOAD=true && yarn install

COPY . /ProtectedPlanet

EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
