ARG RUBY_VERSION=3.3.7
ARG NODE_VERSION=26.8.1

FROM ubuntu:24.04
ARG RUBY_VERSION
ARG NODE_VERSION

# GEM_HOME/BUNDLE_PATH came free with the ruby:* base image before; they have to
# be set explicitly here, and must stay at /usr/local/bundle -- that is the path
# docker-compose.yml mounts the shared `protectedplanet_bundler` volume on.
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    GEM_HOME=/usr/local/bundle \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_APP_CONFIG=/usr/local/bundle \
    BUNDLE_SILENCE_ROOT_WARNING=1
ENV PATH="/usr/local/ruby-${RUBY_VERSION}/bin:/usr/local/bundle/bin:${PATH}"


# Runtime libraries + the build toolchain, in one layer. The deploy image splits
# these across stages; here the toolchain has to survive into the running
# container so `bundle install` works against the mounted volume.
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg tzdata git \
      # GDAL 3.8.4 + geo stack. OpenFileGDB is built in -- no ESRI SDK, no
      # source build.
      gdal-bin libgdal-dev libproj-dev proj-data proj-bin libgeos-dev \
      # Postgres (pg gem) + spatialite
      libpq-dev libsqlite3-dev libspatialite-dev \
      # image/asset handling. zip is for the .gdb download bundles; unzip is a
      # different package and puppeteer needs it to extract Chrome -- without it
      # the download "succeeds" but leaves no executable behind.
      shared-mime-info zip unzip \
      # toolchain: native gems, and ruby-build's own compile
      build-essential pkg-config autoconf bison \
      libssl-dev libyaml-dev zlib1g-dev libreadline-dev libffi-dev libgmp-dev \
      libxml2-dev libxslt1-dev xz-utils \
      # Chromium runtime deps -- the PDF pipeline drives Puppeteer
      fonts-liberation libgtk-3-0t64 libcups2t64 libx11-xcb1 libxcomposite1 \
      libxdamage1 libxfixes3 libxrandr2 libgbm1 libnss3 libasound2t64 \
      libdrm2 libxkbcommon0 libatk-bridge2.0-0t64 libpango-1.0-0 libcairo2 \
      libxshmfence1 \
 && rm -rf /var/lib/apt/lists/*

# Postgres client from PGDG rather than Ubuntu's 16. The compose stack runs a
# Postgres 17 test database, and a v16 client aborts on "server version
# mismatch"; v17 still talks to the v11 development server.
RUN install -d /usr/share/postgresql-common/pgdg \
 && curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
      -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc \
 && echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt noble-pgdg main" \
      > /etc/apt/sources.list.d/pgdg.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends postgresql-client-17 \
 && rm -rf /var/lib/apt/lists/*

# Ruby via ruby-build, same version and mechanism as the deploy image.
RUN git clone --depth 1 https://github.com/rbenv/ruby-build.git /tmp/ruby-build \
 && PREFIX=/usr/local /tmp/ruby-build/install.sh \
 && ruby-build "${RUBY_VERSION}" "/usr/local/ruby-${RUBY_VERSION}" \
 && rm -rf /tmp/ruby-build \
 && ruby -v | grep -q "${RUBY_VERSION}"

# The compose commands use login shells (`bash -l -c`), which source /etc/profile
# and rebuild PATH from scratch -- dropping the ENV above. Re-prepend it here.
RUN printf 'export PATH=/usr/local/ruby-%s/bin:/usr/local/bundle/bin:$PATH\n' "${RUBY_VERSION}" \
      > /etc/profile.d/ruby.sh

# Node from the official tarball, plus corepack. Yarn's version is deliberately
# NOT pinned here -- corepack reads it from package.json's "packageManager",
# which is the single source of truth (`npm i -g yarn` would only get classic 1.x).
#
# corepack must be installed from npm: Node 26 no longer bundles it. The v26
# tarball ships only node/npm/npx, so the plain `corepack enable` that worked on
# 24 dies with "corepack: not found" (exit 127).
#
# node itself needs libatomic.so.1, which comes in via build-essential above.
RUN curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" -o /tmp/node.tar.xz \
 && tar -xf /tmp/node.tar.xz -C /usr/local --strip-components=1 \
 && rm /tmp/node.tar.xz \
 && npm install -g corepack@latest \
 && corepack enable

WORKDIR /ProtectedPlanet

# Gems first so this layer caches independently of app code.
COPY Gemfile Gemfile.lock ./
RUN gem install bundler --no-document \
 && bundle install --jobs 4 --retry 3

# Pre-warm corepack's Yarn cache (/root/.cache/node/corepack, not a mounted
# path) with whatever version package.json asks for, so the first `yarn` in the
# container doesn't stop to download one. package.json itself is shadowed by the
# bind mount at runtime; only the cache matters.
COPY package.json ./
RUN COREPACK_ENABLE_DOWNLOAD_PROMPT=0 corepack install \
 && yarn -v

EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
