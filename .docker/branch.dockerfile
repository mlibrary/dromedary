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
RUN useradd -m -d $APP_PATH -u $UID -g $GID -o -s /bin/bash $UNAME
RUN mkdir /var/opt/app
RUN mkdir /var/opt/app/data
RUN mkdir /var/opt/app/gems
RUN chown $UID:$GID /var/opt/app
RUN chown $UID:$GID /var/opt/app/data
RUN touch $UID:$GID /var/opt/app/data/.keep
RUN chown $UID:$GID /var/opt/app/gems
RUN touch $UID:$GID /var/opt/app/gems/.keep
COPY --chown=$UID:$GID . /opt/app

USER $UNAME
WORKDIR $APP_PATH

RUN rm *.lock
RUN gem install 'bundler:~>2.2.21'
RUN bundle config --local build.sassc --disable-march-tune-native
RUN bundle install
RUN yarn install

ENV RAILS_ENV production
RUN bundle exec rails assets:precompile

CMD ["bundle", "exec", "bin/rails", "s", "-b", "0.0.0.0"]
