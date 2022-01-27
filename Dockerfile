FROM ruby:2.6
ARG UNAME=app
ARG UID=1000
ARG GID=1000

RUN apt-get update -yqq && \
    apt-get install -yqq --no-install-recommends \
    apt-transport-https nodejs
RUN gem install 'bundler:~>1.17.3' 'bundler:~>2.0.2'

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

#ENV SOLR_URL=

#ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["bin/rails", "s", "-b", "0.0.0.0"]
