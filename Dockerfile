FROM ruby:2.6
ARG UNAME=app
ARG UID=1000
ARG GID=1000

RUN apt-get update -yqq && \
    apt-get install -yqq --no-install-recommends \
    apt-transport-https nodejs vim
RUN gem install 'bundler:~>2.1.4'

RUN groupadd -g $GID -o $UNAME
RUN useradd -m -d /usr/src/app -u $UID -g $GID -o -s /bin/bash $UNAME
RUN mkdir -p /gems && chown $UID:$GID /gems

COPY Gemfile* /usr/src/app/

ENV RAILS_LOG_TO_STDOUT true
ENV BUNDLE_PATH /gems

WORKDIR /usr/src/app
RUN bundle install

COPY . /usr/src/app

RUN mkdir /usr/src/app/data
RUN chown -R $UID:$GID /usr/src/app

USER $UNAME
#ENV SOLR_URL=

#ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["bin/rails", "s", "-b", "0.0.0.0"]
