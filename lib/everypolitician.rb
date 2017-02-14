
module EveryPolitician
  class ScraperRun
    def initialize(id: SecureRandom.uuid, table: 'data', index_fields: nil, default_index_fields: %i(id term))
      @run_data = { id: id, started: Time.now }
      @table = table
      @index_fields = index_fields
      @default_index_fields = default_index_fields
      ScraperWiki.save_sqlite(%i(id), run_data, 'runs')
      ScraperWiki.sqliteexecute('DELETE FROM %s' % table) rescue nil
    end

    def save_all(data, debugging: ENV['MORPH_PRINT_DATA'])
      data.each { |r| puts r.reject { |_, v| v.to_s.empty? }.sort_by { |k, _| k }.to_h } if debugging
      ScraperWiki.save_sqlite(index_fields_from(data), data, table)
      ScraperWiki.save_sqlite(%i(id), run_data.merge(ended: Time.now), 'runs')
    end

    def error(e)
      ScraperWiki.save_sqlite(%i(id), run_data.merge(errored: Time.now), 'runs')
      # TODO: do something better with the error
      raise e
    end

    private

    attr_reader :run_data, :table, :index_fields, :default_index_fields

    def index_fields_from(data)
      index_fields || (data.first.keys & default_index_fields)
    end
  end

  class Scraper
    def initialize(url:, default_data: {})
      @url = url
      @default_data = default_data
    end

    def run
      scraper_run.save_all(data)
    rescue => e
      scraper_run.error(e)
    end

    private

    attr_reader :url, :default_data

    def scraper_run
      @scraper_run = EveryPolitician::ScraperRun.new
    end

    def scrape(h)
      url, klass = h.to_a.first
      klass.new(response: Scraped::Request.new(url: url).response)
    end
  end
end
