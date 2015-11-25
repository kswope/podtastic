#!/usr/bin/env ruby

require_relative 'lib'
require "rss"
require 'pp'
require 'fileutils'
require 'net/http'
require 'bundler'
Bundler.require

# aws sdk wants credentials in env,
ENV['AWS_ACCESS_KEY_ID']     = ENV['PODTASTIC_AWS_ACCESS_KEY_ID']
ENV['AWS_SECRET_ACCESS_KEY'] = ENV['PODTASTIC_AWS_SECRET_ACCESS_KEY']

MAX_FEED_ITEM_AGE=7
STREAM_OUTPUT_ROOT='var/active_streams'
SYNC_ROOT='var/sync_dir'


#------------------------------------------------------------------------------
# program args validation and assignment
#------------------------------------------------------------------------------
unless ARGV.length == 3
  raise './streamer.rb program_name stream_url duration'
end

program_name = ARGV[0]
stream_url = ARGV[1]
duration = ARGV[2]
duration = duration.to_i * 60 # convert input minutes to seconds


# run
# ./streamer name stream_url duration

# streamripper #{url} -d #{stream_dir} -a #{filename} -l #{duration}
# streamripper http://stream.abacast.net/playlist/entercom-wrkoammp3-64.m3u -a out.mp3 -l 10

 
# http://www.wntk.com/wntk.m3u
# http://stream.abacast.net/playlist/entercom-wrkoammp3-64.m3u


# unique identifier
prog_key = sanitize_filename([program_name,stream_url].join('_'))

stream_dir = File.join(STREAM_OUTPUT_ROOT, prog_key)
FileUtils.mkdir_p(stream_dir)


duration = 1 # DEBUG
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


#------------------------------------------------------------------------------
# Engage lockfile because multiples of this script may be running
#------------------------------------------------------------------------------
# lock stuff
Lockfile.debug = true
Lockfile.new('/tmp/podtastic.lock') do


  #------------------------------------------------------------------------------
  # Get rss feed from S3 bucket (bucket will be called upon again at end of script)
  #------------------------------------------------------------------------------
  rssio = StringIO.new # place to put bucket contents (what is this, c?)
  resource = Aws::S3::Resource.new
  bucket = resource.bucket('podtastic')
  bucket.object('rss.xml').get(response_target:rssio)
  feed = RSS::Parser.parse(rssio)


  #------------------------------------------------------------------------------
  # Remove old feeds and their corresponding streams
  #------------------------------------------------------------------------------
  # feed.items.delete_if do |item|
  #   pubDate = DateTime.parse(item.pubDate.to_s)
  #   if (DateTime.now - pubDate).to_i > MAX_FEED_ITEM_AGE
  #     # delete file here
  #     puts "deleting " + item.enclosure.url
  #     true
  #   end
  # end



  #------------------------------------------------------------------------------
  # Create whole new replacement feed xml
  #------------------------------------------------------------------------------
  newrss = RSS::Maker.make("2.0") do |maker|

    maker.channel.link = 'http://example.com'
    maker.channel.description = 'Channel description'
    maker.channel.title = 'Channel Title'


    # first item will be our new stream
    maker.items.new_item do |new_item|
      new_item.updated = Time.now.to_s
      new_item.title = program_name
      new_item.enclosure.url = stream_url
      new_item.enclosure.type = 'mp3'
      new_item.enclosure.length = 123
    end



    # now add previous items to new feed
    feed.items.each do |feed_item|
      maker.items.new_item do |new_item|
        new_item.updated = feed_item.pubDate
        new_item.title =  feed_item.title
        new_item.enclosure.url = feed_item.enclosure.url
        new_item.enclosure.type = feed_item.enclosure.type
        new_item.enclosure.length = feed_item.enclosure.length
      end
    end

  end



  #------------------------------------------------------------------------------
  # Replace previous feed xml with our new feed
  #------------------------------------------------------------------------------
  bucket.put_object(key:'rss.xml', acl:'public-read', body:newrss.to_s)



  #------------------------------------------------------------------------------
  # Disengage lockfile because multiples of this script may be running
  #------------------------------------------------------------------------------
end

