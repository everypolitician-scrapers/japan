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

class LetterListPage < Scraped::HTML
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
    tds[3].text
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

def scrape(h)
  url, klass = h.to_a.first
  klass.new(response: Scraped::Request.new(url: url).response)
end

start = 'http://www.shugiin.go.jp/internet/itdb_english.nsf/html/statics/member/mem_a.htm'
front = scrape start => LetterListPage
pages = [front, front.letter_pages.map { |url| scrape url => LetterListPage }].flatten

data = pages.flat_map(&:members).map(&:to_h)
# puts data
ScraperWiki.save_sqlite(%i(name area), data)
