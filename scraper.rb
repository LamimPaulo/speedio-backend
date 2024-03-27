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
    to_send = [];
    data = Nokogiri::HTML(html)

    company_info = {
      name: data.xpath('//*[@id="overview"]/div/div/div/div[5]/div/dl/div[1]/dd/a').text,
      foundation_year: data.xpath('//*[@id="overview"]/div/div/div/div[5]/div/dl/div[2]/dd').text,
      num_employees: data.xpath('//*[@id="overview"]/div/div/div/div[5]/div/dl/div[3]/dd').text,
      hq: data.xpath('//*[@id="overview"]/div/div/div/div[5]/div/dl/div[4]/dd').text,
      yr_revenue: data.xpath('//*[@id="overview"]/div/div/div/div[5]/div/dl/div[5]/dd').text,
      industry: data.xpath('//*[@id="overview"]/div/div/div/div[5]/div/dl/div[6]/dd').text,
    }

    global_variation = data.at('//*[@id="overview"]/div/div/div/div[3]/div/div[1]/div/span')
    country_variation = data.at('//*[@id="overview"]/div/div/div/div[3]/div/div[2]/span')

    rank = {
      global: data.xpath('//*[@id="overview"]/div/div/div/div[3]/div/div[1]/div/p').text,
      global_variation: global_variation.text,
      global_variation_direction: global_variation['class']&.include?('change--up') ? 'up' : 'down',
      country: data.xpath('//*[@id="overview"]/div/div/div/div[3]/div/div[2]/p[2]').text,
      country_variation: country_variation.text,
      country_variation_direction: country_variation['class']&.include?('change--up') ? 'up' : 'down',
      # category: data.xpath('//*[@id="overview"]/div/div/div/div[3]/div/div[2]/p[2]').text,
      # category_variation: category_variation.text,
      # category_variation_direction: category_variation['class']&.include?('change--up') ? 'up' : 'down'
    }
    
    visits = {
      total: data.xpath('//*[@id="overview"]/div/div/div/div[4]/div[2]/div[1]/p[2]').text,
      bounce_rate: data.xpath('//*[@id="overview"]/div/div/div/div[4]/div[2]/div[2]/p[2]').text,
      pages_per_visit: data.xpath('//*[@id="overview"]/div/div/div/div[4]/div[2]/div[3]/p[2]').text,
      avg_duration: data.xpath('//*[@id="overview"]/div/div/div/div[4]/div[2]/div[4]/p[2]').text,
    }

    traffic_rank = {
      country: {
        current_month: data.xpath('//*[@id="highcharts-7wjwe4y-0"]/div[2]/span/div/div/strong').text,
        last_month: data.xpath('//*[@id="highcharts-7wjwe4y-0"]/div[2]/span/div/div/strong').text,
        two_months_ago: data.xpath('//*[@id="highcharts-7wjwe4y-0"]/div[2]/span/div/div/strong').text,
        similarly_sites: {
          two_above: {pos: data.xpath('//*[@id="ranking"]/div/div/div[2]/div[2]/div/div/div[1]/span[1]').text, domain: data.xpath('//*[@id="ranking"]/div/div/div[2]/div[2]/div/div/div[1]/span[3]').text},
          one_above: {pos: data.xpath('//*[@id="ranking"]/div/div/div[2]/div[2]/div/div/div[2]/span[1]').text, domain: data.xpath('//*[@id="ranking"]/div/div/div[2]/div[2]/div/div/div[2]/span[3]').text},
          one_below: {pos: data.xpath('//*[@id="ranking"]/div/div/div[2]/div[2]/div/div/div[4]/span[1]').text, domain: data.xpath('//*[@id="ranking"]/div/div/div[2]/div[2]/div/div/div[4]/span[3]').text},
          two_below: {pos: data.xpath('//*[@id="ranking"]/div/div/div[2]/div[2]/div/div/div[5]/span[1]').text, domain: data.xpath('//*[@id="ranking"]/div/div/div[2]/div[2]/div/div/div[5]/span[3]').text},
        }
      },
      global: {
        # TODO
      },
    }

    return {
      company_info: company_info,
      rank: rank,
      visits: visits,
      traffic_rank: traffic_rank,
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

end