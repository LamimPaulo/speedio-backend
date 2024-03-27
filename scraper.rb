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
    target_url = "https://www.similarweb.com/website/#{@url}/"
    make_request(target_url)
  end


  def scrape_data(html)
    data = Nokogiri::HTML(html)

    company_info = extract_company_info(data)
    rank = extract_rank(data)
    visits = extract_visits(data)
    traffic_rank = extract_traffic_rank(data)
    top_countries = extract_top_countries(data)
    composition = extract_composition(data)

    {
      company_info: company_info,
      rank: rank,
      visits: visits,
      traffic_rank: traffic_rank,
      top_countries: top_countries,
      composition: composition,
    }
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
      global_variation: data.xpath("#{rank_base_xpath}[1]/div/span").text,
      global_variation_direction: extract_variation_direction(global_variation),
      
      country: data.xpath("#{rank_base_xpath}[2]/p[2]").text,
      country_variation: data.xpath("#{rank_base_xpath}[2]/span").text,
      country_variation_direction: extract_variation_direction(country_variation),
  
      category_pos: data.xpath("#{rank_base_xpath}[3]/div[1]/p").text,
      category_name: data.xpath("#{rank_base_xpath}[3]/div[2]/a").text,
    }
  end

  def extract_visits(data)
    visits_base_xpath = '//*[@id="overview"]/div/div/div/div[4]/div[2]/div'.freeze
  
    total = data.xpath("#{visits_base_xpath}[1]/p[2]").text
    bounce_rate = data.xpath("#{visits_base_xpath}[2]/p[2]").text
    pages_per_visit = data.xpath("#{visits_base_xpath}[3]/p[2]").text
    avg_duration = data.xpath("#{visits_base_xpath}[4]/p[2]").text
  
    {
      total: total,
      bounce_rate: bounce_rate,
      pages_per_visit: pages_per_visit,
      avg_duration: avg_duration
    }
  end
  
  def extract_traffic_rank(data)
    alike_base_xpath = '[@id="ranking"]/div/div/div[2]/div[2]/div/div/div'.freeze
  
    current_month = data.xpath('//*[@id="highcharts-7wjwe4y-0"]/div[2]/span/div/div/strong').text
  
    similarly_sites = {
      two_above: {
        pos: data.xpath("//*#{alike_base_xpath}[1]/span[1]").text,
        domain: data.xpath("//*#{alike_base_xpath}[1]/span[3]").text
      },
      one_above: {
        pos: data.xpath("//*#{alike_base_xpath}[2]/span[1]").text,
        domain: data.xpath("//*#{alike_base_xpath}[2]/span[3]").text
      },
      one_below: {
        pos: data.xpath("//*#{alike_base_xpath}[4]/span[1]").text,
        domain: data.xpath("//*#{alike_base_xpath}[4]/span[3]").text
      },
      two_below: {
        pos: data.xpath("//*#{alike_base_xpath}[5]/span[1]").text,
        domain: data.xpath("//*#{alike_base_xpath}[5]/span[3]").text
      }
    }
  
    {
      country: {
        current_month: current_month,
        last_month: current_month, #need to find a way to fetch from chart.
        two_months_ago: current_month, # //
        similarly_sites: similarly_sites
      },
      global: {
        # TODO
      }
    }
  end

  def extract_top_countries(data)
    top_co_base_xpath = '//*[@id="geography"]/div/div/div[2]/div[2]/div/div'.freeze
    top_countries = {}
  
    (1..5).each do |i|
      top_countries["position_#{i}"] = {
        name: data.xpath("#{top_co_base_xpath}[#{i}]/div[2]/a").text,
        percent: data.xpath("#{top_co_base_xpath}[#{i}]/div[2]/div/span[1]").text
      }
    end
  
    others_index = 6
    top_countries[:others] = {
      name: data.xpath("#{top_co_base_xpath}[#{others_index}]/div[2]/span").text,
      percent: data.xpath("#{top_co_base_xpath}[#{others_index}]/div[2]/div/span[1]").text
    }
  
    top_countries
  end

  def extract_composition(data)
    composition_base_xpath = '//*[@id="demographics"]/div/div/div[2]/div[2]/ul/li'.freeze
    composition = {
      gender: [],
      age: []
    }
  
    (1..2).each do |i|
      composition[:gender] << {
        name: data.xpath("#{composition_base_xpath}[#{i}]/span[1]").text,
        percent: data.xpath("#{composition_base_xpath}[#{i}]/span[2]").text
      }
    end
  
    composition[:age] << { #chart...
      percent: data.xpath('/html/body/div[1]/div/main/div/div/div[3]/section[3]/div/div/div[2]/div[1]/div/div/div/svg/g[6]/g[1]/text/tspan').text
    }
  
    composition
  end

  def extract_variation_direction(variation)
    return "-" if variation.nil?
  
    if variation["class"]&.include?("change--up")
      "up"
    elsif variation["class"]&.include?("change--down")
      "down"
    else
      "-"
    end
  end
  

end