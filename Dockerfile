ARG RUBY_VERSION=2.7.8
ARG RUBY_SLIM="-slim"
FROM ruby:${RUBY_VERSION}${RUBY_SLIM} AS base

ARG UNAME=app
ARG UID=1000
ARG GID=1000
ARG ARCH=amd64

ARG BUNDLER_VERSION=2.4.22
ARG NODE_VERSION=20

RUN rm -f /etc/apt/apt.conf.d/docker-clean && \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' \
    > /etc/apt/apt.conf.d/keep-cache
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt update && apt-get --no-install-recommends install -yq \
    apt-transport-https \
    build-essential \
    curl \
    git \
    unzip \
    libpq-dev \
    ##### FIXME: remove these once useless gems are trimmed \
    libmariadb-dev \
    libsqlite3-dev \
    ##### What is netcat here for???
    netcat

RUN --mount=type=cache,sharing=locked,target=/var/cache/apt \
    --mount=type=cache,sharing=locked,target=/var/lib/apt \
    curl -SLO https://deb.nodesource.com/nsolid_setup_deb.sh && \
    chmod 500 nsolid_setup_deb.sh && \
    ./nsolid_setup_deb.sh ${NODE_VERSION} && \
    apt-get install nodejs -yq

RUN gem install bundler:${BUNDLER_VERSION}

RUN groupadd -g $GID -o $UNAME
RUN useradd -m -d /opt/app -u $UID -g $GID -o -s /bin/bash $UNAME

ENV RAILS_LOG_TO_STDOUT true

WORKDIR /opt/app
COPY Gemfile* .

#############
FROM base AS base-dev

RUN --mount=type=cache,sharing=locked,target=/var/cache/apt \
    --mount=type=cache,sharing=locked,target=/var/lib/apt \
    apt-get --no-install-recommends install -yq \
      fd-find \
      less \
      ripgrep \
      vim-tiny

############
FROM base AS gems-prod

RUN --mount=type=cache,id=med-bundle-prod,sharing=locked,target=/vendor/bundle \
    --mount=type=cache,sharing=locked,target=/vendor/cache \
    bundle config set path /vendor/bundle && \
    bundle config set cache_path /vendor/cache && \
    bundle config set cache_all true && \
    bundle config set without 'development test' && \
    bundle config build.sassc --disable-march-tune-native && \
    bundle cache --no-install && \
    bundle install --local && \
    bundle clean && \
    bundle config unset cache_path && \
    bundle config set path /gems && \
    mkdir -p /gems && \
    cp -ar /vendor/bundle/* /gems


#############
FROM base-dev AS gems-dev

RUN --mount=type=cache,id=med-bundle-dev,sharing=locked,target=/vendor/bundle \
    --mount=type=cache,sharing=locked,target=/vendor/cache \
    bundle config set path /vendor/bundle && \
    bundle config set cache_path /vendor/cache && \
    bundle config set cache_all true && \
    bundle cache --no-install && \
    bundle config build.sassc --disable-march-tune-native && \
    bundle install --local && \
    bundle clean && \
    bundle config unset cache_path && \
    bundle config set path /gems && \
    mkdir -p /gems && \
    cp -ar /vendor/bundle/* /gems


#############
FROM gems-prod AS production

ARG RAILS_RELATIVE_URL_ROOT

COPY . .
RUN chown -R ${UID}:${GID} /gems && chown -R ${UID}:${GID} /opt/app


EXPOSE 3000
USER $UNAME

### temporarily required to start up/precompile
ENV SOLR_ROOT=bogus
ENV SOLR_COLLECTION=bogus
###

ENV RAILS_ENV production
ENV RAILS_SERVE_STATIC_FILES true
ENV SECRET_KEY_BASE 121222bccca
ENV RAILS_RELATIVE_URL_ROOT=${RAILS_RELATIVE_URL_ROOT}

RUN bin/rails assets:precompile

CMD ["bin/rails", "s", "-b", "0.0.0.0"]


############
FROM gems-dev AS development

COPY . .
RUN chown -R ${UID}:${GID} /gems && chown -R ${UID}:${GID} /opt/app

RUN bundle config build.sassc --disable-march-tune-native
RUN bundle config set path /gems

EXPOSE 3000
USER $UNAME

CMD ["bin/rails", "s", "-b", "0.0.0.0"]
