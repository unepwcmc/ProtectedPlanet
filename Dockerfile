ARG RUBY_VERSION=4.0.6
ARG NODE_VERSION=26.8.1
ARG COREPACK_VERSION=0.36.0

FROM ubuntu:24.04
ARG RUBY_VERSION
ARG NODE_VERSION
ARG COREPACK_VERSION

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
      # rustc/cargo build YJIT into ruby (build-time only; see the ruby-build step)
      rustc cargo \
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
# YJIT is compiled in via RUBY_CONFIGURE_OPTS. `config.yjit = true` has been set
# for non-local environments since load_defaults 8.1, but the Ruby built here had
# no YJIT, so railties' `if config.yjit && defined?(RubyVM::YJIT.enable)` guard
# silently skipped it -- the live staging container reported yjit=not-compiled
# while the config said true. Building with it makes the existing config real.
#
# rustc/cargo are BUILD-ONLY: YJIT is compiled into the ruby binary, so nothing
# Rust-related is needed at runtime. Ubuntu 24.04 ships rustc 1.75, comfortably
# over the 1.60 YJIT needs for a release-mode build.
#
# NOT ZJIT: Ruby 4.0 ships it, but upstream still advise against production use.
RUN git clone --depth 1 https://github.com/rbenv/ruby-build.git /tmp/ruby-build \
 && PREFIX=/usr/local /tmp/ruby-build/install.sh \
 && RUBY_CONFIGURE_OPTS="--enable-yjit" \
    ruby-build "${RUBY_VERSION}" "/usr/local/ruby-${RUBY_VERSION}" \
 && rm -rf /tmp/ruby-build \
 && ruby -v | grep -q "${RUBY_VERSION}" \
 && ruby -e 'abort("YJIT missing from this build") unless defined?(RubyVM::YJIT)'

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
# corepack is installed straight from its registry tarball, NOT via
# `npm install -g corepack@latest`. Node 26 unbundled corepack (a bare
# `corepack enable` exits 127), but the npm that ships with Node 26.6.0 through
# 26.8.2 (npm 11.18.0 - 11.19.1) is broken for EVERY install, global or local:
#   npm error cannot set sizeCalculation without setting maxSize or maxEntrySize
# Reproduced 2026-09-14 in clean `node:26.8.1-slim` and `ubuntu:24.04` + tarball,
# on both arm64 and amd64, installing nothing more exotic than `is-odd`. It is an
# upstream npm bug, not ours. Nothing else here needs npm (yarn comes from
# corepack, per package.json's "packageManager"), so the tarball path sidesteps it
# entirely. Revisit when a Node 26 patch ships a working npm.
# Reverted to linux-x64 deliberately. A native arm64 dev image would fix the
# frontend toolchain (vue-tsc, tailwind and npm all misbehave under Rosetta --
# the same `vite build --mode test` that fails emulated completed in 6.6s on
# native arm64, measured 2026-09-14), but it cannot work: Chrome for Testing has
# no linux-arm64 build, so `puppeteer browsers install chrome` fetches the x64
# binary and the image build dies on
#   rosetta error: failed to open elf at /lib64/ld-linux-x86-64.so.2
# and Ubuntu 24.04 arm64 has no usable chromium package to substitute (`chromium`
# has no candidate; `chromium-browser` is a snap shim). Chrome is needed for
# local PDF generation, so x64 + emulation stays until that changes. The cost is
# that `vite build` cannot run locally; CI builds assets fine.
RUN curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" -o /tmp/node.tar.xz \
 && tar -xf /tmp/node.tar.xz -C /usr/local --strip-components=1 \
 && rm /tmp/node.tar.xz \
 && curl -fsSL "https://registry.npmjs.org/corepack/-/corepack-${COREPACK_VERSION}.tgz" -o /tmp/corepack.tgz \
 && mkdir -p /usr/local/lib/node_modules/corepack \
 && tar -xzf /tmp/corepack.tgz -C /usr/local/lib/node_modules/corepack --strip-components=1 \
 && rm /tmp/corepack.tgz \
 && chmod +x /usr/local/lib/node_modules/corepack/dist/corepack.js \
 && ln -sf /usr/local/lib/node_modules/corepack/dist/corepack.js /usr/local/bin/corepack \
 && corepack enable

WORKDIR /ProtectedPlanet

# Gems first so this layer caches independently of app code.
COPY Gemfile Gemfile.lock ./
RUN gem install bundler --no-document \
 && bundle install --jobs 4 --retry 3

# JS deps. .yarnrc.yml sets nodeLinker: node-modules and must be present before
# `yarn install`, or Yarn Berry silently defaults to PnP -- no node_modules/.bin,
# so the puppeteer CLI below cannot be resolved. .puppeteerrc.cjs pins the Chrome
# version and has to be here for the same reason.
#
# The corepack pre-warm (/root/.cache/node/corepack, not a mounted path) picks up
# whatever package.json's "packageManager" asks for, so the first `yarn` in the
# container doesn't stop to download one.
COPY package.json yarn.lock .yarnrc.yml* .puppeteerrc.cjs ./
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0
RUN corepack install && yarn -v

# Chrome for Testing lives inside node_modules rather than puppeteer's default
# $HOME/.cache/puppeteer, because node_modules is the one path docker-compose.yml
# bind-mounts from the host across install/web/sidekiq. The default is
# container-local: the download lands in whichever container ran it, is invisible
# to the others, and is wiped on every recreate. When this line went missing,
# docker/scripts/pdf-chrome exited instantly with "no Chrome at ..." and every PDF
# job silently fell back to launching its own browser.
ENV PUPPETEER_CACHE_DIR=/ProtectedPlanet/node_modules/.puppeteer-cache

# PUPPETEER_SKIP_DOWNLOAD: puppeteer's postinstall download has no retry and is
# not routed through the build cache mount below. Chrome is installed explicitly,
# right after, in a controlled step instead.
RUN PUPPETEER_SKIP_DOWNLOAD=true yarn install --immutable \
 || PUPPETEER_SKIP_DOWNLOAD=true yarn install

# Same controlled install as Dockerfile.deploy -- see the long note there for why
# each part is shaped this way. In short: the cache mount is wiped only AFTER a
# failed attempt (never before the first, or Chrome is re-downloaded every build),
# $PUPPETEER_CACHE_DIR is cleared on every attempt so a half-finished download
# cannot read as "already installed", and verify-puppeteer.js is a hard gate that
# actually launches the browser rather than trusting a directory to exist.
COPY app/frontend/backend-scripts ./app/frontend/backend-scripts
RUN --mount=type=cache,target=/puppeteer-dl-cache \
    n=0; \
    until rm -rf "$PUPPETEER_CACHE_DIR" \
        && PUPPETEER_CACHE_DIR=/puppeteer-dl-cache ./node_modules/.bin/puppeteer browsers install chrome; do \
        n=$((n+1)); \
        if [ "$n" -ge 3 ]; then echo "Chrome download failed after 3 attempts" >&2; exit 1; fi; \
        echo "Chrome download attempt $n failed, clearing the cache and retrying in 5s..."; \
        find /puppeteer-dl-cache -mindepth 1 -delete; \
        sleep 5; \
    done \
 && mkdir -p "$PUPPETEER_CACHE_DIR" \
 && cp -a /puppeteer-dl-cache/. "$PUPPETEER_CACHE_DIR/" \
 && node app/frontend/backend-scripts/verify-puppeteer.js

EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
