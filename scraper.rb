# #!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'open-uri/cached'

OpenURI::Cache.cache_path = '.cache'

def noko_for(url)
  Nokogiri::HTML(open(url).read)
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
    next if tds.size < 1
    data = {
      name: tds[1].text,
      faction: tds[2].text,
      image: URI.join(url, tds[0].css('img/@src').to_s).to_s,
      area: tds[3].text
    }
    ScraperWiki.save_sqlite([:name, :area], data)
  end
end

scrape_pages('http://www.shugiin.go.jp/internet/itdb_english.nsf/html/statics/member/mem_a.htm')
