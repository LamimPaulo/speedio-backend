require 'nokogiri'
require 'open-uri'
require 'uri'
require 'net/http'
require 'openssl'
require 'securerandom'

class WebScraper

  def initialize(url)
    @url = url
  end

  def scrape!
    target_url = "https://www.similarweb.com/website/#{@url}"
    make_request(target_url)
  end

  private

  def make_request(url)
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    
    cookie = new_cookie('https://www.similarweb.com/website')
    headers = {
      'User-Agent' => 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
      'Cookie' => cookie,
    }

    response = http.get(uri.request_uri, headers)
    html = response.body

    scraped = scrape_data(html)
  end

  def scrape_data(html)
    data = Nokogiri::HTML(html)

    company_info = extract_company_info(data)
    rank = extract_rank(data)
    visits = extract_visits(data)
    traffic_rank = extract_traffic_rank(data)

    {
      company_info: company_info,
      rank: rank,
      visits: visits,
      traffic_rank: traffic_rank
    }
  end

  def new_cookie(url)
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    headers = {
      'User-Agent' => 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
      'Accept' => 'text/html',
    }

    response = http.get(uri.request_uri, headers)

    cookie = response['set-cookie']
  end

  def extract_company_info(data)
    company_info_base_xpath = '//*[@id="overview"]/div/div/div/div[5]/div/dl/div'.freeze

    name_xpath = "#{company_info_base_xpath}[1]/dd/a"
    foundation_year_xpath = "#{company_info_base_xpath}[2]/dd"
    num_employees_xpath = "#{company_info_base_xpath}[3]/dd"
    hq_xpath = "#{company_info_base_xpath}[4]/dd"
    yr_revenue_xpath = "#{company_info_base_xpath}[5]/dd"
    industry_xpath = "#{company_info_base_xpath}[6]/dd"
    
    company_info = {
      name: safe_extract(data, name_xpath),
      foundation_year: safe_extract(data, foundation_year_xpath),
      num_employees: safe_extract(data, num_employees_xpath),
      hq: safe_extract(data, hq_xpath),
      yr_revenue: safe_extract(data, yr_revenue_xpath),
      industry: safe_extract(data, industry_xpath),
    }
  end

  def extract_rank(data)
    rank_base_xpath = '//*[@id="overview"]/div/div/div/div[3]/div/div'.freeze

    global_variation = data.at("#{rank_base_xpath}[1]/div/span")
    country_variation = data.at("#{rank_base_xpath}[2]/span")

    rank = {
      global: safe_extract(data, "#{rank_base_xpath}[1]/div/p"),
      global_variation: safe_extract(data, "#{rank_base_xpath}[1]/div/span"),
      global_variation_direction: global_variation["class"]&.include?("change--up") ? "up" : "down",
      country: safe_extract(data, "#{rank_base_xpath}[2]/p[2]"),
      country_variation: safe_extract(data, "#{rank_base_xpath}[2]/span"),\
      country_variation_direction: country_variation["class"]&.include?("change--up") ? "up" : "down",
    }
  end

  def extract_visits(data)
    visits_base_xpath = '//*[@id="overview"]/div/div/div/div[4]/div[2]/div'.freeze
    
    visits = {
      total: safe_extract(data, "#{visits_base_xpath}[1]/p[2]"),
      bounce_rate: safe_extract(data, "#{visits_base_xpath}[2]/p[2]"),
      pages_per_visit: safe_extract(data, "#{visits_base_xpath}[3]/p[2]"),
      avg_duration: safe_extract(data, "#{visits_base_xpath}[4]/p[2]"),
    }
  end

  def extract_traffic_rank(data)
    alike_base_xpath = '[@id="ranking"]/div/div/div[2]/div[2]/div/div/div'.freeze
    traffic_rank = {
      country: {
        current_month: safe_extract(data, '//*[@id="highcharts-7wjwe4y-0"]/div[2]/span/div/div/strong'),
        last_month: safe_extract(data, '//*[@id="highcharts-7wjwe4y-0"]/div[2]/span/div/div/strong'),
        two_months_ago: safe_extract(data, '//*[@id="highcharts-7wjwe4y-0"]/div[2]/span/div/div/strong'),
        similarly_sites: {
          two_above: {pos: safe_extract(data, "//*#{alike_base_xpath}[1]/span[1]"), domain: safe_extract(data, "//*#{alike_base_xpath}[1]/span[3]")},
          one_above: {pos: safe_extract(data, "//*#{alike_base_xpath}[2]/span[1]"), domain: safe_extract(data, "//*#{alike_base_xpath}[2]/span[3]")},
          one_below: {pos: safe_extract(data, "//*#{alike_base_xpath}[4]/span[1]"), domain: safe_extract(data, "//*#{alike_base_xpath}[4]/span[3]")},
          two_below: {pos: safe_extract(data, "//*#{alike_base_xpath}[5]/span[1]"), domain: safe_extract(data, "//*#{alike_base_xpath}[5]/span[3]")},
        }
      },
      global: {
        # TODO
      },
    }
  end

  def safe_extract(data, xpath)
    data.xpath(xpath).text
  rescue Nokogiri::XML::XPath::SyntaxError
    '-'
  end

end