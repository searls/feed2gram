module Feed2Gram
  class UpdatesCache
    def update!(cache, results, cache_path)
      cache.updated_at = Time.now
      results.group_by { |result| result.status }
        .transform_values { |results| results.map { |result| result.post.url } }
        .each do |status, urls|
        cache[status] += urls
      end

      File.write(cache_path, cache.as_yaml)
    end
  end
end
