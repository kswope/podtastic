#!/usr/bin/env ruby

require "rss"
require 'pp'
require 'fileutils'
require_relative 'lib'

MAX_AGE=7
STREAM_OUTPUT_ROOT='var/stream_output'
SYNC_ROOT='var/sync_dir'

unless ARGV.length == 3
  raise './streamer.rb program_name stream_url duration'
end


# run
# ./streamer name stream_url duration

# streamripper #{url} -d #{stream_dir} -a #{filename} -l #{duration}
# streamripper http://stream.abacast.net/playlist/entercom-wrkoammp3-64.m3u -a out.mp3 -l 10

 
# http://www.wntk.com/wntk.m3u
# http://stream.abacast.net/playlist/entercom-wrkoammp3-64.m3u


program_name = ARGV[0] or raise usage
stream_url = ARGV[1] or raise usage
duration = ARGV[2] or raise usage
duration = duration.to_i * 60 # convert input minutes to seconds

# unique identifier
prog_key = sanitize_filename([program_name,stream_url].join('_'))

stream_dir = File.join(STREAM_OUTPUT_ROOT, prog_key)
FileUtils.mkdir_p(stream_dir)


duration = 5 # DEBUG
command = "streamripper #{stream_url} -d #{stream_dir} -a out -l #{duration} -o always"
puts "running #{command}"
system(command)





# copy output to sync_dir
sync_dir = File.join(SYNC_ROOT, prog_key)
FileUtils.mkdir_p(sync_dir)

# will this always be mp3 extension?
FileUtils.cp(File.join(stream_dir, 'out.mp3'), sync_dir)

# cleanup
FileUtils.rmtree(stream_dir)


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

# puts feed



# we need to make a new Maker and copy old feed just to append old feed (bleh)
# (because RSS::Parser.items doesn't have new_item
newrss = RSS::Maker.make("2.0") do |maker|


  maker.channel.link = feed.channel.link
  maker.channel.description = feed.channel.description
  maker.channel.title = feed.channel.title

  feed.items.each do |feed_item|

    pp feed_item

    maker.items.new_item do |new_item|
      new_item.updated = feed_item.pubDate
      new_item.title =  feed_item.title
      new_item.enclosure.url = feed_item.enclosure.url
      new_item.enclosure.type = feed_item.enclosure.type
      new_item.enclosure.length = feed_item.enclosure.length
    end

  end


  # add our new item
  maker.items.new_item do |new_item|
    new_item.updated = Time.now.to_s
    new_item.title = program_name
    new_item.enclosure.url = stream_url
    new_item.enclosure.type = 'mp3'
    new_item.enclosure.length = 123
  end



end

puts newrss

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
