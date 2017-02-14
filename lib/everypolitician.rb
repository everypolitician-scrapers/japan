module Everypolitician
  class Scraper
    def initialize(config: {}, default_data: {}, unique_fields: nil, default_unique_fields: %i(id term start_date))
      @config = config
      @default_data = default_data
      @unique_fields = unique_fields
      @default_unique_fields = default_unique_fields
    end

    def to_a
      data_with_defaults
    end

    def index_fields
      unique_fields || (data.first.keys & default_unique_fields)
    end

    private

    attr_reader :config, :default_data, :unique_fields, :default_unique_fields

    def data_with_defaults
      @data_with_defaults ||= data.map { |d| default_data.merge(d) }
    end

    def scrape(h)
      url, klass = h.to_a.first
      klass.new(response: Scraped::Request.new(url: url).response)
    end
  end
end
