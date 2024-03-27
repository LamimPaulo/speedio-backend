require 'minitest/autorun'
require_relative '../scraper'

class ScraperTest < Minitest::Test
  def test_scraper
    file_path = File.expand_path(File.join(__dir__, 'mock_similarweb.html'))

    File.open(file_path, 'r') do |file|
      html = file.read
      scraper = WebScraper.new('')
      data = scraper.scrape_data(html)
      
      #TODO
    end
  end
end
