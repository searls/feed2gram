FROM ruby:3.2.2-alpine

WORKDIR /srv
COPY Gemfile Gemfile.lock feed2gram.gemspec ./
COPY lib/feed2gram/version.rb lib/feed2gram/
RUN apk update && \
    apk add autoconf bash git gcc make musl-dev && \
    bundle install && \
    apk del --purge --rdepends git gcc autoconf make musl-dev
ADD . .
VOLUME /config
CMD ["--config", "/config/feed2gram.yml"]
ENTRYPOINT ["/srv/bin/daemon"]
