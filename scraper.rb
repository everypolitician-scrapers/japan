#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'nokogiri'
require 'pry'
require 'scraped'
require 'scraperwiki'

# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '.cache'
require 'scraped_page_archive/open-uri'

class LetterListPageEn < Scraped::HTML
  decorator Scraped::Response::Decorator::AbsoluteUrls

  field :members do
    wanted_rows.map { |tr| fragment tr => MemberRowEn }
  end

  field :letter_pages do
    noko.css('p.r + table tr td.c a/@href').map(&:text)
  end

  private

  def all_rows
    noko.css('h1#TopContents + table tr', 'h1#TopContents + br + table tr')
  end

  def wanted_rows
    all_rows.reject { |tr| tr.css('td').empty? }
  end
end

class MemberRowEn < Scraped::HTML
  field :id do
    File.basename(image, '.jpg')
  end

  field :name do
    raw_name.gsub(/M[rs]\./, '').tidy
  end

  field :gender do
    return 'male' if raw_name.include?('Mr.')
    return 'female' if raw_name.include?('Ms.')
  end

  field :faction do
    tds[2].children.map(&:text).join(' ').tidy
  end

  field :image do
    tds[0].css('img/@src').to_s
  end

  field :area do
    tds[3].text.tidy
  end

  field :term do
    46
  end

  field :source do
    url.to_s
  end

  private

  def tds
    noko.css('td')
  end

  def raw_name
    tds[1].text
  end
end

class LetterListPageJp < Scraped::HTML
  decorator Scraped::Response::Decorator::AbsoluteUrls

  field :members do
    noko.xpath('//tr[td[@class="sh1td5"]]').map do |tr|
      fragment tr => MemberRowJp
    end
  end

  field :letter_pages do
    noko.xpath('//div[@id="breadcrumb"]/following-sibling::p/a/@href').map(&:text) - [url]
  end
end

class MemberRowJp < Scraped::HTML
  field :id do
    File.basename(source, '.html')
  end

  field :name__ja do
    tds[0].text.tidy
  end

  field :name__ja_hira do
    tds[1].text.tidy
  end

  field :faction__ja do
    tds[2].text.tidy
  end

  field :area__ja do
    tds[3].text.tidy
  end

  field :source do
    tds[0].css('a/@href').text
  end

  private

  def tds
    noko.css('td')
  end
end

class MemberPageJp < Scraped::HTML
  decorator Scraped::Response::Decorator::AbsoluteUrls

  field :image do
    noko.css('#photo img/@src').text
  end
end

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

ScraperWiki.sqliteexecute('DELETE FROM data') rescue nil
ScraperWiki.save_sqlite(%i[name area], data)
