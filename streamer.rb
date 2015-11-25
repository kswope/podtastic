#!/usr/bin/env ruby

require_relative 'lib'
require "rss"
require 'pp'
require 'net/http'
require 'fileutils'
require 'bundler'
Bundler.require

# aws sdk wants credentials in env,
ENV['AWS_ACCESS_KEY_ID']     = ENV['PODTASTIC_AWS_ACCESS_KEY_ID']
ENV['AWS_SECRET_ACCESS_KEY'] = ENV['PODTASTIC_AWS_SECRET_ACCESS_KEY']

MAX_FEED_ITEM_AGE=5 # days



#------------------------------------------------------------------------------
# program args validation and assignment
#------------------------------------------------------------------------------
unless ARGV.length == 4
  puts 'usage: ./streamer.rb feed_name program_name stream_url duration'
  exit
end

feed_name = ARGV[0]
feed_object = "#{feed_name}.xml"
program_name = ARGV[1]
stream_url = ARGV[2]
duration = ARGV[3]
# convert duration to seconds like streamripper wants
duration = duration.to_i * 60 

paths = PathManager.new(show: program_name, 
                        stream: stream_url, 
                        bucket:'podtastic',
                        var: '/tmp/podtastic')

bucket = Aws::S3::Resource.new.bucket(paths.bucket)


# run
# ./streamer name stream_url duration

# streamripper #{url} -d #{stream_dir} -a #{filename} -l #{duration}
# streamripper http://stream.abacast.net/playlist/entercom-wrkoammp3-64.m3u -a out.mp3 -l 10

 
# http://www.wntk.com/wntk.m3u
# http://stream.abacast.net/playlist/entercom-wrkoammp3-64.m3u


FileUtils.mkdir_p(paths.tmp_dir)


duration = 10 # DEBUG
command = "streamripper #{paths.stream} -d #{paths.tmp_dir} -a out -l #{duration} -o always"
puts "running #{command}"
system(command)


#------------------------------------------------------------------------------
# Upload stream to S3
#------------------------------------------------------------------------------
bucket.put_object(key:paths.remote_filename, 
                  acl:'public-read', 
                  body:File.open(paths.streamed_filepath))


#------------------------------------------------------------------------------
# Engage lockfile because multiples of this script may be running
#------------------------------------------------------------------------------
# Lockfile.debug = true
Lockfile.new('/tmp/podtastic.lock') do


  #------------------------------------------------------------------------------
  # Get rss feed from S3 bucket (bucket will be called upon again at end of script)
  #------------------------------------------------------------------------------

  if bucket.object(feed_object).exists?

    rssio = StringIO.new # place to put bucket contents (what is this, c?)
    bucket.object(feed_object).get(response_target:rssio)
    feed = RSS::Parser.parse(rssio)


    #------------------------------------------------------------------------------
    # Remove old feeds and their corresponding streams
    #------------------------------------------------------------------------------
    feed.items.delete_if do |item|
      pubTime = Time.parse(item.pubDate.to_s)
      if (Time.now - pubTime).to_i > MAX_FEED_ITEM_AGE * 60 # * 60 * 24
        key = item.enclosure.url.match(/([^\/]*)$/)[1]
        puts "deleting #{key}"
        bucket.delete_objects(delete:{objects:[{key:key}]})
        true
      end
    end

  end


  #------------------------------------------------------------------------------
  # Create whole new replacement feed xml
  #------------------------------------------------------------------------------
  newrss = RSS::Maker.make("2.0") do |maker|

    maker.channel.link = 'http://example.com'
    maker.channel.title = 'Podtastic'
    maker.channel.description = 'My Ripped Radio'

    # first item will be our new stream
    maker.items.new_item do |new_item|
      new_item.updated = Time.now.to_s
      new_item.title = paths.show
      new_item.enclosure.url = paths.stream_bucket_url
      new_item.enclosure.type = paths.stream_type
      new_item.enclosure.length = duration
    end

    # now add previous items to new feed
    if feed
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

  end


  #------------------------------------------------------------------------------
  # Replace previous feed xml with our new feed
  #------------------------------------------------------------------------------
  bucket.put_object(key:feed_object, acl:'public-read', body:newrss.to_s)


  #------------------------------------------------------------------------------
  # cleanup
  #------------------------------------------------------------------------------
  FileUtils.rmtree(paths.tmp_dir)


  #------------------------------------------------------------------------------
  # Disengage lockfile because multiples of this script may be running
  #------------------------------------------------------------------------------
end

