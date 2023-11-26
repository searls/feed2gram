module Feed2Gram
  Result = Struct.new(:post, :status, keyword_init: true)

  class PublishesPosts
    def publish(posts, config, options)
      post_limit = options.limit || posts.size
      puts "Publishing #{post_limit} posts to Instagram" if options.verbose

      # reverse to post oldest first (most Atom feeds are reverse-chronological)
      posts.reverse.take(post_limit).map { |post|
        begin
          if post.medias.size == 1
            puts "Publishing #{post.media_type.downcase} for: #{post.url}" if options.verbose
            publish_single_media(post, config, options)
          else
            puts "Publishing carousel for: #{post.url}" if options.verbose
            publish_carousel(post, config, options)
          end
        rescue => e
          warn "Failed to post #{post.url}: #{e.message}"
          Result.new(post: post, status: :failed)
        end
      }
    end

    private

    def publish_single_media(post, config, options)
      media = post.medias.first

      puts "Creating media resource for URL - #{media.url}" if options.verbose
      container_id = Http.post("/#{config.instagram_id}/media", {
        :media_type => post.media_type,
        :caption => post.caption,
        :access_token => config.access_token,
        media.video? ? :video_url : :image_url => media.url
      }.compact)[:id]

      if media.video?
        wait_for_media_to_upload!(media.url, container_id, config, options)
      end

      puts "Publishing media for URL - #{media.url}" if options.verbose
      Http.post("/#{config.instagram_id}/media_publish", {
        creation_id: container_id,
        access_token: config.access_token
      })
      Result.new(post: post, status: :posted)
    end

    def publish_carousel(post, config, options)
      media_containers = post.medias.take(10).map { |media|
        puts "Creating media resource for URL - #{media.url}" if options.verbose
        res = Http.post("/#{config.instagram_id}/media", {
          :media_type => media.media_type,
          :is_carousel_item => true,
          :access_token => config.access_token,
          media.video? ? :video_url : :image_url => media.url
        }.compact)
        res[:id]
      }
      post.medias.select(&:video?).zip(media_containers).each { |media, container_id|
        wait_for_media_to_upload!(media.url, container_id, config, options)
      }

      puts "Creating carousel media resource for post - #{post.url}" if options.verbose
      carousel_id = Http.post("/#{config.instagram_id}/media", {
        caption: post.caption,
        media_type: post.media_type,
        children: media_containers.join(","),
        access_token: config.access_token
      })[:id]
      wait_for_media_to_upload!(post.url, carousel_id, config, options)

      puts "Publishing carousel media for post - #{post.url}" if options.verbose
      Http.post("/#{config.instagram_id}/media_publish", {
        creation_id: carousel_id,
        access_token: config.access_token
      })
      Result.new(post: post, status: :posted)
    end

    # Good ol' loop-and-sleep. Haven't loop do'd in a while
    def wait_for_media_to_upload!(url, container_id, config, options)
      wait_attempts = 0
      loop do
        if wait_attempts > 90
          warn "Giving up waiting for media to upload after waiting 120 seconds: #{url}"
          break
        end

        res = Http.get("/#{container_id}", {
          fields: "status_code",
          access_token: config.access_token
        })
        puts "Upload status #{res[:status_code]} after #{wait_attempts + 1} check for #{url}" if options.verbose
        if res[:status_code] == "FINISHED"
          break
        elsif res[:status_code] == "IN_PROGRESS"
          wait_attempts += 1
          sleep 1
        else
          warn "Unexpected status code (#{res[:status_code]}) uploading: #{url}"
          break
        end
      end
    end
  end
end
