module Feed2Gram
  Cache = Struct.new(:updated_at, :posted, :failed, :skipped, keyword_init: true) do
    def as_yaml
      to_h.transform_keys(&:to_s).to_yaml.gsub(/^---\n/, "")
    end
  end

  class LoadsCache
    def load(cache_path)
      if File.exist?(cache_path)
        yaml = YAML.load_file(cache_path, permitted_classes: [Time])
        Cache.new(**yaml)
      else
        Cache.new(posted: [], failed: [], skipped: [])
      end
    end
  end
end
