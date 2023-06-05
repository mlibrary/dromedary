FROM ruby:2.7

ARG UNAME=app
ARG UID=1000
ARG GID=1000

ENV DEBIAN_FRONTEND noninteractive

RUN curl https://deb.nodesource.com/setup_12.x | bash
RUN curl https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN apt-get update -yqq && \
    apt-get install -yqq --no-install-recommends \
    vim nodejs yarn apt-transport-https

ENV APP_PATH /opt/app
RUN groupadd -g $GID -o $UNAME
RUN useradd -M -d $APP_PATH -u $UID -g $GID -o -s /bin/bash $UNAME

COPY . $APP_PATH
WORKDIR $APP_PATH

RUN ls -a
RUN rm *.lock
RUN gem install 'bundler:~>2.2.21'
RUN bundle config --local build.sassc --disable-march-tune-native

RUN --mount=type=secret,id=gh_package_read_token \
  read_token="$(cat /run/secrets/gh_package_read_token)" \
  && BUNDLE_RUBYGEMS__PKG__GITHUB__COM=${read_token} bundle install
RUN yarn install

RUN chown --recursive $UID:$GID $APP_PATH
USER $UNAME

ENV RAILS_ENV production
RUN bundle exec rails assets:precompile

ENV RAILS_LOG_TO_STDOUT true
CMD ["bundle", "exec", "bin/rails", "s", "-b", "0.0.0.0"]
