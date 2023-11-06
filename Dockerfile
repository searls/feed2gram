FROM ruby:3.2.2-alpine

LABEL org.opencontainers.image.source=https://github.com/searls/feed2gram
LABEL org.opencontainers.image.description="Reads an Atom feed and posts its entries to Instagram (basically feed2toot, but for Instagram)"
LABEL org.opencontainers.image.licenses=GPLv3

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
