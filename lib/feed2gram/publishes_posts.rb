module Feed2Gram
  Result = Struct.new(:post, :status, keyword_init: true)

  class PublishesPosts
    def publish(posts, config, options)
      post_limit = options.limit || posts.size
      puts "Publishing #{post_limit} posts to Instagram" if options.verbose

      # reverse to post oldest first (most Atom feeds are reverse-chronological)
      posts.reverse.take(post_limit).map { |post|
        begin
          if post.images.size == 1
            puts "Publishing single image post for: #{post.url}" if options.verbose
            publish_single_image(post, config)
          else
            puts "Publishing carousel post for: #{post.url}" if options.verbose
            publish_carousel(post, config)
          end
        rescue => e
          warn "Failed to post #{post.url}: #{e.message}"
          Result.new(post: post, status: :failed)
        end
      }
    end

    private

    def publish_single_image(post, config)
      container_response = Http.post("/#{config.instagram_id}/media", {
        image_url: post.images.first,
        caption: post.caption,
        access_token: config.access_token
      })
      Http.post("/#{config.instagram_id}/media_publish", {
        creation_id: container_response[:id],
        access_token: config.access_token
      })
      Result.new(post: post, status: :posted)
    end

    def publish_carousel(post, config)
      image_containers = post.images.take(10).map { |image|
        res = Http.post("/#{config.instagram_id}/media", {
          is_carousel_item: true,
          image_url: image,
          access_token: config.access_token
        })
        res[:id]
      }
      carousel_container = Http.post("/#{config.instagram_id}/media", {
        caption: post.caption,
        media_type: "CAROUSEL",
        children: image_containers.join(","),
        access_token: config.access_token
      })
      Http.post("/#{config.instagram_id}/media_publish", {
        creation_id: carousel_container[:id],
        access_token: config.access_token
      })
      Result.new(post: post, status: :posted)
    end
  end
end
