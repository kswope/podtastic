#!/usr/bin/env ruby

require "rss"
require 'pp'
require 'fileutils'
require_relative 'lib'

rss = RSS::Maker.make("2.0") do |maker|

  maker.channel.author = "kswope"
  maker.channel.updated = Time.now.to_s
  maker.channel.title = "podtastic"
  maker.channel.link = "http://www.ruby-lang.org/en/feeds/news.rss"
  maker.channel.description = "No description"

  maker.channel.items.new_item do |item|
    item.updated = Time.now.to_s
    # item.link = "http://www.ruby-lang.org/en/news/2010/12/25/ruby-1-9-2-p136-is-released/"
    item.title = "something"
    # item.enclosure = RSS::Rss::Channel::Item::Enclosure.new(link, 123, 'audio/mpeg') 
    item.enclosure.url = 'http://somewhere/123.mpeg'
    item.enclosure.type = "audio/mpeg"
    item.enclosure.length = 123

  end

end

puts rss
