# frozen_string_literal: true

require 'scraped'

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
