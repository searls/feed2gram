module Feed2Gram
  Cache = Struct.new(:updated_at, :posted, :failed, :skipped, keyword_init: true) do
    def as_yaml
      to_h.transform_keys(&:to_s).to_yaml.gsub(/^---\n/, "")
    end
  end

  class LoadsCache
    def load(options)
      if File.exist?(options.cache_path)
        puts "Loading cache from: #{options.cache_path}" if options.verbose
        yaml = YAML.load_file(options.cache_path, permitted_classes: [Time])
        Cache.new(**yaml)
      else
        puts "No cache found (looked at '#{options.cache_path}'), initializing a new one" if options.verbose
        Cache.new(posted: [], failed: [], skipped: [])
      end
    end
  end
end
