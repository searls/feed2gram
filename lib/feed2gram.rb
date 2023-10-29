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
    config = LoadsConfig.new.load(options.config_path)
    RefreshesToken.new.refresh!(config, options.config_path) unless options.skip_token_refresh

    cache = LoadsCache.new.load(options.cache_path)
    posts = FiltersPosts.new.filter(ParsesEntries.new.parse(config.feed_url), cache)
    results = if options.populate_cache
      posts.map { |post| Result.new(post: post, status: [:skipped, :failed, :posted].sample) }
    else
      PublishesPosts.new.publish(posts, config, options.limit)
    end
    UpdatesCache.new.update!(cache, results, options.cache_path)
  end
end
