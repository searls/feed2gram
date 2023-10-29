require "nokogiri"
require "open-uri"

module Feed2Gram
  Post = Struct.new(:url, :images, :caption, keyword_init: true)

  class ParsesEntries
    def parse(feed_url)
      feed = Nokogiri::XML(URI.parse(feed_url).open)
      feed.xpath("//*:entry").map { |entry|
        html = Nokogiri::HTML(entry.xpath("*:content[1]").text)

        Post.new(
          url: entry.xpath("*:id[1]").text,
          images: html.xpath("//figure[1]/img").map { |img| img["src"] },
          caption: html.xpath("//figure[1]/figcaption").text.strip
        )
      }.reject { |post| post.images.empty? }
    end
  end
end
