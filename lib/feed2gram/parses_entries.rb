require "nokogiri"
require "open-uri"

module Feed2Gram
  Media = Struct.new(:media_type, :url, keyword_init: true) do
    def video?
      media_type == "VIDEO"
    end
  end
  Post = Struct.new(:media_type, :url, :medias, :caption, keyword_init: true)

  class ParsesEntries
    def parse(feed_url)
      feed = Nokogiri::XML(URI.parse(feed_url).open)
      feed.xpath("//*:entry").map { |entry|
        html = Nokogiri::HTML(entry.xpath("*:content[1]").text)
        medias = html.xpath("//figure[1]/img").map { |img|
          Media.new(
            media_type: (img["data-media-type"] || "image").upcase,
            url: img["src"]
          )
        }

        Post.new(
          media_type: determine_post_media_type(html, medias),
          url: entry.xpath("*:id[1]").text,
          medias: medias,
          caption: html.xpath("//figure[1]/figcaption").text.strip
        )
      }.select { |post|
        if post.medias.empty?
          warn "Skipping post with no <img> tag: #{post.url}"
        elsif ["STORIES", "REELS"].include?(post.media_type) && post.medias.size > 1
          warn "Skipping #{post.media_type.downcase} with more than one <img> tag (only one allowed): #{post.url}"
        else
          true
        end
      }
    end

    private

    def determine_post_media_type(html, medias)
      post_type = html.at("//figure[1]")["data-post-type"]&.upcase
      if ["STORIES", "REELS"].include?(post_type)
        post_type
      elsif medias.size > 1
        "CAROUSEL"
      elsif medias.first.media_type == "VIDEO"
        # The VIDEO value for media_type is deprecated outside carousel items. Use the REELS media type to publish a video to your Instagram feed. Please visit  https://developers.facebook.com/docs/instagram-api/reference/ig-user/media#creating to publish a video.
        "REELS"
      else
        "IMAGE"
      end
    end
  end
end
