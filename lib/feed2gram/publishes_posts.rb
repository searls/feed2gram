module Feed2Gram
  Result = Struct.new(:post, :status, keyword_init: true)

  class PublishesPosts
    def publish(posts, config, limit)
      # reverse to post oldest first (most Atom feeds are reverse-chronological)
      posts.reverse.take(limit || posts.size).map { |post|
        begin
          if post.images.size == 1
            publish_single_image(post, config)
          else
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
