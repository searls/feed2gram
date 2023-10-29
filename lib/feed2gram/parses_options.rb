require "optparse"

module Feed2Gram
  Options = Struct.new(:config_path, :cache_path, :limit, :skip_token_refresh, :populate_cache, keyword_init: true) do
    undef_method :cache_path
    def cache_path
      @cache_path || config_path.sub(/\.yml$/, ".cache.yml")
    end
  end

  class ParsesOptions
    def parse(argv)
      options = Options.new(
        config_path: "feed2gram.yml"
      )

      OptionParser.new do |opts|
        opts.banner = "Usage: feed2gram [options]"

        opts.on "--config PATH", "Path of feed2gram YAML configuration (default: feed2gram.yml)" do |path|
          options.config_path = path
        end

        opts.on "--cache-path PATH", "Path of feed2gram's cache file to track processed entries (default: feed2gram.cache.yml)" do |path|
          options.cache_path = path
        end

        opts.on "--limit POST_COUNT", Integer, "Max number of Instagram posts to create on this run (default: unlimited)" do |limit|
          options.limit = limit
        end

        opts.on "--skip-token-refresh", "Don't attempt to exchange the access token for a new long-lived access token" do
          options.skip_token_refresh = true
        end

        opts.on "--populate-cache", "Populate the cache file with any posts found in the feed WITHOUT posting them to Instagram" do
          options.populate_cache = true
        end
      end.parse!(argv)

      options
    end
  end
end
