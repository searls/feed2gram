require "sinatra"

feed_file = ARGV[0] || "sample.xml"
raise "Usage: script/server <path/to/xml/file>" unless File.exist?(feed_file)
puts "Hosting '#{feed_file}' on port 4567"

get "/" do
  send_file feed_file
end
