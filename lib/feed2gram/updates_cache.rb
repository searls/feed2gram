module Feed2Gram
  class UpdatesCache
    def update!(cache, results, options)
      cache.updated_at = Time.now
      results.group_by { |result| result.status }
        .transform_values { |results| results.map { |result| result.post.url } }
        .each do |status, urls|
        cache[status] += urls
      end

      puts "Writing updated cache to: #{options.cache_path}" if options.verbose
      File.write(options.cache_path, cache.as_yaml)
    end
  end
end
