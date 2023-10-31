FROM ruby:3.2.2

WORKDIR /srv
COPY Gemfile Gemfile.lock feed2gram.gemspec .
COPY lib/feed2gram/version.rb lib/feed2gram/
RUN bundle install
ADD . .
ENTRYPOINT ["/srv/exe/feed2gram"]
