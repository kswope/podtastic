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

BUCKET_URL = 'https://s3.amazonaws.com/podtastic'
BUCKET = Aws::S3::Resource.new.bucket('podtastic')

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


# create unique identifier for stream for file naming
prog_key = sanitize_filename([program_name,stream_url].join('_')).downcase

stream_dir = File.join(STREAM_OUTPUT_ROOT, prog_key)
FileUtils.mkdir_p(stream_dir)


duration = 10 # DEBUG
command = "streamripper #{stream_url} -d #{stream_dir} -a out -l #{duration} -o always"
puts "running #{command}"
system(command)



#------------------------------------------------------------------------------
# file/name/path munging
#------------------------------------------------------------------------------

# Get the output file name from the cue file - could be out.mp3, out.aac, who knows
out_file_name = File.open("#{stream_dir}/out.cue", &:gets).match(/^FILE \"(.*)\"/)[1]

# absolute path to out file
out_file_path = File.expand_path(File.join(stream_dir, out_file_name))

# name we will give to stream file served
url_name = out_file_name.gsub('out', prog_key)

# full public url
url_file = File.join(BUCKET_URL, url_name)



#------------------------------------------------------------------------------
# Upload stream to S3
#------------------------------------------------------------------------------
BUCKET.put_object(key:url_name, acl:'public-read', body:File.open(out_file_path))



#------------------------------------------------------------------------------
# cleanup
#------------------------------------------------------------------------------
FileUtils.rmtree(stream_dir)

exit

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
  BUCKET.object('rss.xml').get(response_target:rssio)
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

