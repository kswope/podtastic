#!/usr/bin/env ruby

require "rss"
require 'pp'
require 'fileutils'
require 'bundler'
Bundler.require

MAX_AGE=4
STREAM_OUTPUT_DIR='output'

FileUtils.mkdir_p(STREAM_OUTPUT_DIR)

# run
# ./streamer stream_url duration

# streamripper #{url} -d #{output_dir} -a #{filename} -l #{duration}
# streamripper http://stream.abacast.net/playlist/entercom-wrkoammp3-64.m3u -a out.mp3 -l 10

 
# http://www.wntk.com/wntk.m3u
# http://stream.abacast.net/playlist/entercom-wrkoammp3-64.m3u
url = ARGV[0]
filename= ARGV[1]
duration = 5

command = "streamripper #{url} -d #{STREAM_OUTPUT_DIR} -a #{filename} -l #{duration}"
puts "running #{command}"
system(command)

exit

# finish downloading feed into publish dir
# lock file
# open existing RSS feed
# parse RSS feed
# add our own link
# write feed to publish dir 
# S3 sync
# unlock file

rss = File.read('feed.rss')
feed = RSS::Parser.parse(rss)

# expire old items
feed.items.delete_if do |item|
  pubDate = DateTime.parse(item.pubDate.to_s)
  if (DateTime.now - pubDate).to_i > MAX_AGE
    # delete file here
    puts "deleting " + item.enclosure.url
    true
  end
end

puts feed


# rss = RSS::Maker.make("2.0") do |maker|
#
#   maker.channel.author = "kswope"
#   maker.channel.updated = Time.now.to_s
#   maker.channel.title = "podtastic"
#   maker.channel.link = "http://www.ruby-lang.org/en/feeds/news.rss"
#   maker.channel.description = "No description"
#
#   maker.items.new_item do |item|
#     item.updated = Time.now.to_s
#     # item.link = "http://www.ruby-lang.org/en/news/2010/12/25/ruby-1-9-2-p136-is-released/"
#     item.title = "something"
#     # item.enclosure = RSS::Rss::Channel::Item::Enclosure.new(link, 123, 'audio/mpeg') 
#     item.enclosure.url = 'http://somewhere/123.mpeg'
#     item.enclosure.type = "audio/mpeg"
#     item.enclosure.length = 123
#
#   end
#
# end
#
# puts rss
