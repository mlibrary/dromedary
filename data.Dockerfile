FROM ruby:2.6

ENV DATA_FILE=In_progress_MEC_files.zip
ENV data_dir=/opt/app-data
ENV build_dir=/opt/app-data/build
ENV SOLR_URL=http://localhost:9639/solr
ARG UNAME=app
ARG UID=1000
ARG GID=1000

RUN apt-get update -yqq && \
    apt-get install -yqq --no-install-recommends \
    apt-transport-https nodejs
RUN gem install 'bundler:2.1.4'

RUN groupadd -g $GID -o $UNAME
RUN useradd -m -d /usr/src/app -u $UID -g $GID -o -s /bin/bash $UNAME
RUN mkdir -p /gems && chown $UID:$GID /gems

USER $UNAME
COPY --chown=$UID:$GID Gemfile* /usr/src/app/

ENV RAILS_LOG_TO_STDOUT true
ENV BUNDLE_PATH /gems

WORKDIR /usr/src/app
RUN bundle install

COPY --chown=$UID:$GID . /usr/src/app

USER $UNAME
RUN mkdir -p /usr/src/app/data/build

RUN bin/dromedary newdata prepare $DATA_FILE; bin/dromedary newdata index