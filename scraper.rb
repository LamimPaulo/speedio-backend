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
      name: data.xpath(name_xpath).text,
      foundation_year: data.xpath(foundation_year_xpath).text,
      num_employees: data.xpath(num_employees_xpath).text,
      hq: data.xpath(hq_xpath).text,
      yr_revenue: data.xpath(yr_revenue_xpath).text,
      industry: data.xpath(industry_xpath).text,
    }
  end

  def extract_rank(data)
    rank_base_xpath = '//*[@id="overview"]/div/div/div/div[3]/div/div'.freeze

    global_variation = data.at("#{rank_base_xpath}[1]/div/span")
    country_variation = data.at("#{rank_base_xpath}[2]/span")

    rank = {
      global: data.xpath("#{rank_base_xpath}[1]/div/p").text,
      global_variation: global_variation.text,
      global_variation_direction: global_variation["class"]&.include?("change--up") ? "up" : "down",
      country: data.xpath("#{rank_base_xpath}[2]/p[2]").text,
      country_variation: country_variation.text,
      country_variation_direction: country_variation["class"]&.include?("change--up") ? "up" : "down",
      # category: data.xpath("#{rank_base_xpath}[2]/p[2]").text,
      # category_variation: category_variation.text,
      # category_variation_direction: category_variation["class"]&.include?("change--up") ? "up" : "down"
    }
  end

  def extract_visits(data)
    visits_base_xpath = '//*[@id="overview"]/div/div/div/div[4]/div[2]/div'.freeze
    
    visits = {
      # total: data.xpath("#{visits_base_xpath}[1]/p[2]").text,
      bounce_rate: data.xpath("#{visits_base_xpath}[2]/p[2]").text,
      pages_per_visit: data.xpath("#{visits_base_xpath}[3]/p[2]").text,
      avg_duration: data.xpath("#{visits_base_xpath}[4]/p[2]").text,
    }
  end

  def extract_traffic_rank(data)
    alike_base_xpath = '[@id="ranking"]/div/div/div[2]/div[2]/div/div/div'.freeze
    traffic_rank = {
      country: {
        current_month: data.xpath('//*[@id="highcharts-7wjwe4y-0"]/div[2]/span/div/div/strong').text,
        last_month: data.xpath('//*[@id="highcharts-7wjwe4y-0"]/div[2]/span/div/div/strong').text,
        two_months_ago: data.xpath('//*[@id="highcharts-7wjwe4y-0"]/div[2]/span/div/div/strong').text,
        similarly_sites: {
          two_above: {pos: data.xpath("//*#{alike_base_xpath}[1]/span[1]").text, domain: data.xpath("//*#{alike_base_xpath}[1]/span[3]").text},
          one_above: {pos: data.xpath("//*#{alike_base_xpath}[2]/span[1]").text, domain: data.xpath("//*#{alike_base_xpath}[2]/span[3]").text},
          one_below: {pos: data.xpath("//*#{alike_base_xpath}[4]/span[1]").text, domain: data.xpath("//*#{alike_base_xpath}[4]/span[3]").text},
          two_below: {pos: data.xpath("//*#{alike_base_xpath}[5]/span[1]").text, domain: data.xpath("//*#{alike_base_xpath}[5]/span[3]").text},
        }
      },
      global: {
        # TODO
      },
    }
  end

end