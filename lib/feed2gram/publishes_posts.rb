module Feed2Gram
  Result = Struct.new(:post, :status, keyword_init: true)
  class FacebookSucksAtDownloadingFilesError < StandardError; end

  class PublishesPosts
    SECONDS_PER_UPLOAD_CHECK = ENV.fetch("SECONDS_PER_UPLOAD_CHECK") { 30 }.to_i
    MAX_UPLOAD_STATUS_CHECKS = ENV.fetch("MAX_UPLOAD_STATUS_CHECKS") { 100 }.to_i
    RETRIES_AFTER_UPLOAD_TIMEOUT = ENV.fetch("RETRIES_AFTER_UPLOAD_TIMEOUT") { 5 }.to_i

    def publish(posts, config, options)
      post_limit = options.limit || posts.size
      puts "Publishing #{post_limit} posts to Instagram" if options.verbose

      # reverse to post oldest first (most Atom feeds are reverse-chronological)
      posts.reverse.take(post_limit).map { |post|
        begin
          retry_if_upload_times_out(RETRIES_AFTER_UPLOAD_TIMEOUT, post, options) do
            if post.medias.size == 1
              puts "Publishing #{post.media_type.downcase} for: #{post.url}" if options.verbose
              publish_single_media(post, config, options)
            else
              puts "Publishing carousel for: #{post.url}" if options.verbose
              publish_carousel(post, config, options)
            end
          end
        rescue => e
          warn "Failed to post #{post.url}: #{e.message}"
          e.backtrace.join("\n").each_line { |line| warn line }
          Result.new(post: post, status: :failed)
        end
      }
    end

    # Pseudo-public "API mode"
    def create_single_media_container(post, config)
      media = post.medias.first
      Http.post("/#{config.instagram_id}/media", {
        :media_type => post.media_type,
        :caption => post.caption,
        :access_token => config.access_token,
        :cover_url => media.cover_url,
        media.video? ? :video_url : :image_url => media.url
      }.compact)[:id]
    end

    # Pseudo-public "API mode"
    def create_carousel_media_container(media, config)
      res = Http.post("/#{config.instagram_id}/media", {
        :media_type => media.media_type,
        :is_carousel_item => true,
        :access_token => config.access_token,
        media.video? ? :video_url : :image_url => media.url
      }.compact)
      res[:id]
    end

    # Pseudo-public "API mode"
    def create_carousel_container(post, media_containers, config)
      Http.post("/#{config.instagram_id}/media", {
        caption: post.caption,
        media_type: post.media_type,
        children: media_containers.join(","),
        access_token: config.access_token
      })[:id]
    end

    # Pseudo-public "API mode"
    def upload_finished?(container_id, config)
      res = Http.get("/#{container_id}", {
        fields: "status_code,status",
        access_token: config.access_token
      })

      if res[:status_code] == "FINISHED"
        true
      elsif res[:status_code] == "IN_PROGRESS"
        false
      else
        raise <<~MSG
          Unexpected status code (#{res[:status_code]}) uploading container: #{container_id}"

          API sent back this: #{res[:status]}

          Error codes can be looked up here: https://developers.facebook.com/docs/instagram-platform/instagram-graph-api/reference/error-codes/
        MSG
      end
    end

    # Pseudo-public "API mode"
    def publish_container(container_id, config)
      res = Http.post("/#{config.instagram_id}/media_publish", {
        creation_id: container_id,
        access_token: config.access_token
      })
      res[:id]
    end

    # Pseudo-public "API mode"
    def get_media_permalink(media_id, config)
      res = Http.get("/#{media_id}", {
        fields: "permalink",
        access_token: config.access_token
      })
      res[:permalink]
    end

    private

    def retry_if_upload_times_out(times_remaining, post, options, &blk)
      blk.call
    rescue FacebookSucksAtDownloadingFilesError
      if times_remaining > 0
        puts "Will retry with attempt ##{RETRIES_AFTER_UPLOAD_TIMEOUT - times_remaining + 2} after Facebook failed to download a video without timing out for: #{post.url}" if options.verbose
        retry_if_upload_times_out(times_remaining - 1, post, options, &blk)
      else
        warn "Failed to post #{post.url} after #{RETRIES_AFTER_UPLOAD_TIMEOUT} retries due to Facebook timing out on video downloads"
        Result.new(post: post, status: :failed)
      end
    end

    def publish_single_media(post, config, options)
      media = post.medias.first

      puts "Creating media resource for URL - #{media.url}" if options.verbose
      container_id = create_single_media_container(post, config)

      if media.video?
        wait_for_media_to_upload!(media.url, container_id, config, options)
      end

      puts "Publishing media for URL - #{media.url}" if options.verbose
      publish_container(container_id, config)
      Result.new(post: post, status: :posted)
    end

    def publish_carousel(post, config, options)
      media_containers = post.medias.take(10).map { |media|
        puts "Creating media resource for URL - #{media.url}" if options.verbose
        create_carousel_media_container(media, config)
      }
      post.medias.zip(media_containers).each { |media, container_id|
        if media.video?
          wait_for_media_to_upload!(media.url, container_id, config, options)
        end
      }

      puts "Creating carousel media resource for post - #{post.url}" if options.verbose
      carousel_id = create_carousel_container(post, media_containers, config)

      wait_for_media_to_upload!(post.url, carousel_id, config, options)

      puts "Publishing carousel media for post - #{post.url}" if options.verbose
      publish_container(carousel_id, config)
      Result.new(post: post, status: :posted)
    end

    # Good ol' loop-and-sleep. Haven't loop do'd in a while
    def wait_for_media_to_upload!(url, container_id, config, options)
      wait_attempts = 0
      loop do
        if wait_attempts > MAX_UPLOAD_STATUS_CHECKS
          warn "Giving up waiting for media to upload after waiting #{SECONDS_PER_UPLOAD_CHECK * MAX_UPLOAD_STATUS_CHECKS} seconds: #{url}"
          raise FacebookSucksAtDownloadingFilesError
        end

        begin
          puts "Uploading after waiting #{wait_attempts * SECONDS_PER_UPLOAD_CHECK} seconds for IG to download #{url}" if options.verbose
          if upload_finished?(container_id, config)
            break
          else
            wait_attempts += 1
            sleep SECONDS_PER_UPLOAD_CHECK
          end
        rescue => e
          warn e.message
          break
        end
      end
    end
  end
end
