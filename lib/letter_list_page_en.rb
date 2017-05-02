# frozen_string_literal: true

require 'scraped'

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
