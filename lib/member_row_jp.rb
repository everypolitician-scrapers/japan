# frozen_string_literal: true

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
