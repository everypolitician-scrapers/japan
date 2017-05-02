#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'nokogiri'
require 'pry'
require 'scraped'
require 'scraperwiki'

require_rel 'lib'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'
# require 'scraped_page_archive/open-uri'

def scrape(h)
  url, klass = h.to_a.first
  klass.new(response: Scraped::Request.new(url: url).response)
end

def english_data
  start = 'http://www.shugiin.go.jp/internet/itdb_english.nsf/html/statics/member/mem_a.htm'
  front = scrape start => LetterListPageEn
  pages = [front, front.letter_pages.map { |url| scrape url => LetterListPageEn }].flatten
  pages.flat_map(&:members).map(&:to_h)
end

def japanese_data
  start = 'http://www.shugiin.go.jp/internet/itdb_annai.nsf/html/statics/syu/1giin.htm'
  front = scrape start => LetterListPageJp
  pages = [front, front.letter_pages.map { |url| scrape url => LetterListPageJp }].flatten
  pages.flat_map(&:members).map do |mem|
    mem.to_h.merge(scrape(mem.source => MemberPageJp).to_h)
  end
end

jp_data = japanese_data.group_by { |h| h[:id] }

data = english_data.map do |en_mem|
  jp_mem = jp_data[en_mem[:id]] or raise binding.pry
  en_mem.merge(jp_mem.first)
end

# puts data

ScraperWiki.sqliteexecute('DROP TABLE data') rescue nil
ScraperWiki.save_sqlite(%i[name area], data)
