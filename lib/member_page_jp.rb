# frozen_string_literal: true

require 'scraped'

class MemberPageJp < Scraped::HTML
  decorator Scraped::Response::Decorator::AbsoluteUrls

  field :image do
    noko.css('#photo img/@src').text
  end
end
