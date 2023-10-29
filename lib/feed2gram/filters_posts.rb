module Feed2Gram
  class FiltersPosts
    def filter(posts, cache)
      posts.reject { |post|
        cache.posted.include?(post.url) ||
          cache.failed.include?(post.url) ||
          cache.skipped.include?(post.url)
      }
    end
  end
end
