FROM ruby:2.6.3



# Buster is EOL, so point APT to Debian archive mirrors before updating
RUN printf 'deb https://archive.debian.org/debian buster main\n\
deb https://archive.debian.org/debian buster-updates main\n\
deb https://archive.debian.org/debian-security buster/updates main\n' > /etc/apt/sources.list \
 && printf 'Acquire::Check-Valid-Until "0";\nAcquire::Retries "3";\nAcquire::http::Pipeline-Depth "0";\n' > /etc/apt/apt.conf.d/99no-check-valid \
 && apt-get -o Acquire::Check-Valid-Until=false update
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -
RUN echo 'deb [trusted=yes] https://deb.nodesource.com/node_12.x buster main' > /etc/apt/sources.list.d/nodesource.list \
    && echo 'deb-src [trusted=yes] https://deb.nodesource.com/node_12.x buster main' >> /etc/apt/sources.list.d/nodesource.list \
    && DEBIAN_FRONTEND=noninteractive apt-get update \
    && apt-get install --yes nodejs
RUN apt-get install -y \
        apt-utils \
        libgdal-dev \
        libspatialite-dev \
        shared-mime-info \
        build-essential
RUN apt-get install -y postgresql postgresql-client
RUN apt-get install -y zip

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

# This is required for Chromium to work (puppeter triggers Chromium then Chromium needs the following)
RUN apt-get update && \
    apt-get install -y \
        ca-certificates \
        fonts-liberation \
        libgtk-3-0 \
        libcups2 \
        libx11-xcb1 \
        libxcomposite1 \
        libxdamage1 \
        libxfixes3 \
        libxrandr2 \
        libgbm1 \
        libnss3 \
        libasound2 \
        libdrm2 \
        libxkbcommon0 && \
    rm -rf /var/lib/apt/lists/*

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

# As it fails for not able to download r809590 during first time of yarn install so we need to skip it and install it manually later
RUN PUPPETEER_SKIP_DOWNLOAD=true yarn install


COPY . /ProtectedPlanet

EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
