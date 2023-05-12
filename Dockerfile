FROM ruby:2.7

ARG UNAME=app
ARG UID=1000
ARG GID=1000
ARG ARCH=amd64

ENV BUNDLE_PATH /var/opt/app/gems
ENV RAILS_LOG_TO_STDOUT true

RUN curl https://deb.nodesource.com/setup_18.x | bash
RUN curl https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends nodejs yarn

RUN groupadd -g $GID -o $UNAME
RUN useradd -m -d /opt/app -u $UID -g $GID -o -s /bin/bash $UNAME
RUN mkdir -p /var/opt/app/data
RUN mkdir -p /var/opt/app/gems
RUN chown -R $UID:$GID /var/opt/app && touch $UID:$GID /var/opt/app/data/.keep && touch $UID:$GID /var/opt/app/gems/.keep
COPY --chown=$UID:$GID . /opt/app

USER $UNAME
WORKDIR /opt/app
RUN gem install bundler
RUN bundle config --local build.sassc --disable-march-tune-native
RUN bundle install

CMD ["bin/rails", "s", "-b", "127.0.0.1"]
