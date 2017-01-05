# frozen_string_literal: true
# #!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'scraped_page_archive/open-uri'

class String
  def tidy
    gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def get_gender(name)
  return 'male' if name.include?('Mr.')
  return 'female' if name.include?('Ms.')
end

def scrape_pages(url)
  scrape_list(url)
  noko = noko_for(url)
  noko.css('p.r + table tr td.c a').each do |anchor|
    url = URI.join(url, anchor.css('@href').to_s)
    scrape_list(url)
  end
end

def scrape_list(url)
  noko = noko_for(url)
  noko.css('h1#TopContents + table tr', 'h1#TopContents + br + table tr').each do |tr|
    tds = tr.css('td')
    next if tds.empty?
    name = tds[1].text
    gender = get_gender(name)
    name = name.gsub(/M[rs].\s+/, '')
    data = {
      name:    name,
      gender:  gender,
      faction: tds[2].children.map(&:text).join(' ').tidy,
      image:   URI.join(url, tds[0].css('img/@src').to_s).to_s,
      area:    tds[3].text,
      term:    46,
      source:  url.to_s,
    }
    ScraperWiki.save_sqlite(%i(name area), data)
  end
end

scrape_pages('http://www.shugiin.go.jp/internet/itdb_english.nsf/html/statics/member/mem_a.htm')
