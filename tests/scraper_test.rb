require 'minitest/autorun'
require 'awesome_print'
require_relative '../scraper'

class ScraperTest < Minitest::Test
  def test_scraper
    # file_path = File.expand_path(File.join(__dir__, 'mock_similarweb.html'))
    file_path = File.expand_path(File.join(__dir__, 'force.html'))

    File.open(file_path, 'r') do |file|
      html = file.read
      scraper = WebScraper.new('')
      data = scraper.scrape_data(html)

      assert validate_company_info(data[:company_info])
      assert validate_rank(data[:rank])
      assert validate_visits(data[:visits])
      assert validate_traffic_rank(data[:traffic_rank])
      assert validate_top_countries(data[:top_countries])
      assert validate_composition(data[:composition])
      assert validate_target_audience(data[:target_audience])
      assert validate_competitors(data[:competitors])
      assert validate_traffic_source(data[:traffic_source])
      assert validate_top_keywords(data[:top_keywords])
      assert validate_referral_traffic(data[:referral_traffic])
      assert validate_social_network_distribution(data[:social_network_distribution])
      assert validate_link_to_others(data[:link_to_others])
      assert validate_tech_stack(data[:tech_stack])
    
    end
  end

  private

  def validate_company_info(data)
    expected_keys = [:name, :foundation_year, :num_employees, :hq, :yr_revenue, :industry]
    validate_keys(data, expected_keys)
  end
  
  def validate_rank(data)
    expected_keys = [:global, :global_variation, :global_variation_direction, :country, :country_variation, :country_variation_direction, :category_pos, :category_name]
    validate_keys(data, expected_keys)
  end
  
  def validate_visits(data)
    expected_keys = [:total, :bounce_rate, :pages_per_visit, :avg_duration]
    validate_keys(data, expected_keys)
  end
  
  def validate_traffic_rank(data)
    expected_keys = [:country, :global, :category]
    validate_keys(data, expected_keys)
  end
  
  def validate_top_countries(data)
    expected_keys = ["position_1", "position_2", "position_3", "position_4", "position_5", :others]
    validate_keys(data, expected_keys)
  end
  
  def validate_composition(data)
    expected_keys = [:gender, :age]
    validate_keys(data, expected_keys)
  end
  
  def validate_target_audience(data)
    expected_keys = [:top_categories, :other_visited_sites, :top_topics]
    validate_keys(data, expected_keys)
  end
  
  def validate_competitors(data)
    data.count >= 0
  end
  
  def validate_traffic_source(data)
    expected_keys = [:channels, :organic]
    validate_keys(data, expected_keys)
  end
  
  def validate_top_keywords(data)
    expected_keys = [:total_keywords, :list]
    validate_keys(data, expected_keys)
  end
  
  def validate_referral_traffic(data)
    expected_keys = [:total, :category_distribution, :top_referrals]
    validate_keys(data, expected_keys)
  end
  
  def validate_social_network_distribution(data)
    data.count >= 6
  end
  
  def validate_link_to_others(data)
    expected_keys = [:top_outgoing, :category_distribution]
    validate_keys(data, expected_keys)
  end
  
  def validate_tech_stack(data)
    data.count >= 0
  end
  
  def validate_keys(data, expected_keys)
    missing_keys = expected_keys - data.keys
    missing_keys.empty?
  end
end
