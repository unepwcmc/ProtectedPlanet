# Debian buster base. We compile Ruby 3.3 further down via ruby-build rather than
# using a ruby:3.3-* image, because those are bookworm-based and would break the
# GDAL 2.2.3 + ESRI FileGDB source build below (RHEL7 SDK needs old glibc). Keeping
# buster isolates the Ruby 3.3 bump from the Debian/GDAL modernisation, which stays
# in the deploy/infra phases. The base still ships Ruby 2.7; PATH is repointed to
# 3.3 at the ruby-build step.
FROM ruby:2.7-buster

# Buster is EOL, so point APT to Debian archive mirrors before updating
RUN printf 'deb https://archive.debian.org/debian buster main\n\
deb https://archive.debian.org/debian buster-updates main\n\
deb https://archive.debian.org/debian-security buster/updates main\n' > /etc/apt/sources.list \
 && printf 'Acquire::Check-Valid-Until "0";\nAcquire::Retries "3";\nAcquire::http::Pipeline-Depth "0";\n' > /etc/apt/apt.conf.d/99no-check-valid \
 && apt-get -o Acquire::Check-Valid-Until=false update
# Node 24 LTS via official binary tarball. NodeSource dropped Debian buster apt
# support, but the official build targets glibc 2.28 (buster) and runs fine here.
# Vite 5 requires Node 18+; Webpacker 4 (webpack 4) still runs on Node 24 with
# NODE_OPTIONS=--openssl-legacy-provider set on the webpacker service (compose).
ENV NODE_VERSION=24.4.1
RUN curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" -o /tmp/node.tar.xz \
    && tar -xf /tmp/node.tar.xz -C /usr/local --strip-components=1 \
    && rm /tmp/node.tar.xz \
    && node -v && npm -v
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

# Yarn via Corepack (bundled with Node 24) instead of `npm install -g yarn`,
# which only gets classic Yarn 1. Version is pinned to match package.json's
# "packageManager" field.
RUN corepack enable && \
    corepack prepare yarn@4.17.1 --activate

# --- Ruby 3.3, compiled on buster ---
# Placed after the heavy apt/Node/GDAL layers so those stay cache-valid (no GDAL
# recompile) when only Ruby changes. GEM_HOME is inherited from the base
# (/usr/local/bundle), so the shared bundler volume keeps working; gems get
# rebuilt for 3.3 at runtime by the `install` service.
ENV RUBY_VERSION_TARGET=3.3.7
RUN apt-get -o Acquire::Check-Valid-Until=false update && apt-get install -y --no-install-recommends \
        git autoconf bison libssl-dev libyaml-dev zlib1g-dev libreadline-dev libffi-dev libgmp-dev \
 && git clone --depth 1 https://github.com/rbenv/ruby-build.git /tmp/ruby-build \
 && PREFIX=/usr/local /tmp/ruby-build/install.sh \
 && ruby-build "${RUBY_VERSION_TARGET}" "/usr/local/ruby-${RUBY_VERSION_TARGET}" \
 && rm -rf /tmp/ruby-build /var/lib/apt/lists/*
ENV PATH="/usr/local/ruby-${RUBY_VERSION_TARGET}/bin:${PATH}"
# The compose commands use login shells (`bash -l -c`), which source /etc/profile
# and rebuild PATH from scratch -- dropping the ENV above and falling back to the
# base image's Ruby 2.7. This profile.d snippet re-prepends 3.3 for login shells.
RUN printf 'export PATH=/usr/local/ruby-%s/bin:$PATH\n' "${RUBY_VERSION_TARGET}" > /etc/profile.d/ruby-3.3.sh
RUN ruby -v | grep -q "3.3.7" && echo "Ruby 3.3.7 active"

RUN mkdir /ProtectedPlanet
WORKDIR /ProtectedPlanet

ADD Gemfile /ProtectedPlanet/Gemfile
ADD Gemfile.lock /ProtectedPlanet/Gemfile.lock
ADD package.json /ProtectedPlanet/package.json
ADD yarn.lock /ProtectedPlanet/yarn.lock
ADD docker/scripts /ProtectedPlanet/docker/scripts

# We need the following to avoid bundler install error
# https://nokogiri.org/tutorials/installing_nokogiri.html#installing-using-standard-system-libraries
# Install the locked bundler (2.4.22) BEFORE any `bundle` call: Ruby 2.7's
# rubygems errors hard when Gemfile.lock's BUNDLED WITH version is absent
# (Ruby 2.6.3 only warned). Pin every bundle invocation to 2.4.22.
# Bundler 1.17.3 cannot resolve the Rails 6 dependency graph -- it dies with
# `undefined method 'name' for "Gemfile" String`. 2.4.22 is the last 2.x line
# that still supports Ruby 2.7.
# Compile native gems from source rather than pulling precompiled platform gems:
# the precompiled x86_64-linux builds (pg, nokogiri) target a newer glibc than
# buster's 2.28 and fail to load here. Applies to build-time and the runtime
# `install` service (it is an ENV, so it survives the shared bundler volume).
ENV BUNDLE_FORCE_RUBY_PLATFORM=true
RUN gem install bundler -v 2.4.22
RUN bundle _2.4.22_ config build.nokogiri --use-system-libraries
RUN bundle _2.4.22_ install

# As it fails for not able to download r809590 during first time of yarn install so we need to skip it and install it manually later
RUN PUPPETEER_SKIP_DOWNLOAD=true yarn install


COPY . /ProtectedPlanet

EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
