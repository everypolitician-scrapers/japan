# frozen_string_literal: true

require 'scraped'

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
