FROM ruby:2.7 AS app

ARG UNAME=app
ARG UID=1000
ARG GID=1000
#ARG UID 502
#ARG GID 20
ARG ARCH=amd64

RUN curl https://deb.nodesource.com/setup_16.x | bash
RUN curl https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN apt-get update -yqq && \
    apt-get install -yqq --no-install-recommends \
    vim nodejs yarn apt-transport-https \
    netcat

RUN groupadd -g $GID -o $UNAME
RUN useradd -m -d /opt/app -u $UID -g $GID -o -s /bin/bash $UNAME
RUN chown $UID:$GID /opt/app


RUN mkdir /opt/app/data
RUN chown $UID:$GID /opt/app/data
RUN touch /opt/app/data/.keep

RUN mkdir /gems
RUN chown $UID:$GID /gems
RUN touch /gems/.keep

COPY --chown=$UID:$GID . /opt/app

ENV BUNDLE_VERSION 2.4.22
ENV BUNDLE_PATH /gems
RUN gem install bundler:2.4.22

USER ${UID}:${GID}
WORKDIR /opt/app

ENV RAILS_RELATIVE_URL_ROOT /m/middle-english-dictionary
ENV RAILS_LOG_TO_STDOUT true
ENV RAILS_ENV production

# This can be anything but must be set.
ENV SECRET_KEY_BASE 121222bccca

RUN bundle config build.sassc --disable-march-tune-native
RUN bundle config set path /gems
RUN bundle config set without 'test development'
RUN bundle install -j 4

RUN RAILS_ENV=production bin/rails assets:precompile
#CMD ["sleep", "infinity"]
CMD ["bin/rails", "s", "-b", "0.0.0.0"]

FROM nginx:mainline AS assets
ENV NGINX_PORT=80
ENV NGINX_PREFIX=/
COPY --from=app /opt/app/nginx/assets.nginx /etc/nginx/templates/default.conf.template
COPY --from=app /opt/app/public /usr/share/nginx/html/