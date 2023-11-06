FROM ruby:3.2.2

LABEL org.opencontainers.image.source=https://github.com/searls/feed2gram
LABEL org.opencontainers.image.description="Reads an Atom feed and posts its entries to Instagram (basically feed2toot, but for Instagram)"
LABEL org.opencontainers.image.licenses=GPLv3

WORKDIR /srv
COPY Gemfile Gemfile.lock feed2gram.gemspec .
COPY lib/feed2gram/version.rb lib/feed2gram/
RUN bundle install
ADD . .
VOLUME /config
CMD ["--verbose", "--config", "/config/feed2gram.yml"]
ENTRYPOINT ["/srv/exe/feed2gram"]
