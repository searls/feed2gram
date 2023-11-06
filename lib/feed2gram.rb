require_relative "feed2gram/version"
require_relative "feed2gram/http"
require_relative "feed2gram/parses_options"
require_relative "feed2gram/loads_config"
require_relative "feed2gram/refreshes_token"
require_relative "feed2gram/loads_cache"
require_relative "feed2gram/parses_entries"
require_relative "feed2gram/filters_posts"
require_relative "feed2gram/publishes_posts"
require_relative "feed2gram/updates_cache"

module Feed2Gram
  class Error < StandardError; end

  def self.cli(argv)
    options = ParsesOptions.new.parse(argv)
    run(options)
  end

  def self.run(options)
    config = LoadsConfig.new.load(options)
    RefreshesToken.new.refresh!(config, options) unless options.skip_token_refresh

    cache = LoadsCache.new.load(options)
    puts "Loading entries from feed: #{config.feed_url}" if options.verbose
    entries = ParsesEntries.new.parse(config.feed_url)
    puts "Found #{entries.size} entries in feed" if options.verbose
    posts = FiltersPosts.new.filter(entries, cache)
    results = if options.populate_cache
      puts "Populating cache, marking #{posts.size} posts as skipped" if options.verbose
      posts.map { |post| Result.new(post: post, status: :skipped) }
    else
      PublishesPosts.new.publish(posts, config, options)
    end
    UpdatesCache.new.update!(cache, results, options)
  end
end
