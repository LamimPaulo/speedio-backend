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
    target_audience = extract_target_audience(data)
    competitors = extract_competitors(data)
    traffic_source = extract_traffic_source(data)
    top_keywords = extract_top_keywords(data)
    referral_traffic = extract_referral_traffic(data)
    display_advertising = extract_display_advertising(data)
    social_network = extract_social_network(data)
    link_to_others = extract_links_to_others(data)
    tech_stack = extract_tech_stack(data)

    {
      company_info: company_info,
      rank: rank,
      visits: visits,
      traffic_rank: traffic_rank,
      top_countries: top_countries,
      composition: composition,
      target_audience: target_audience,
      competitors: competitors,
      traffic_source: traffic_source,
      top_keywords: top_keywords,
      referral_traffic: referral_traffic,
      social_network_distribution: social_network,
      link_to_others: link_to_others,
      tech_stack: tech_stack,
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
      name: extract_text(data, name_xpath),
      foundation_year: extract_text(data, foundation_year_xpath),
      num_employees: extract_text(data, num_employees_xpath),
      hq: extract_text(data, hq_xpath),
      yr_revenue: extract_text(data, yr_revenue_xpath),
      industry: extract_text(data, industry_xpath),
    }
  end

  def extract_rank(data)
    rank_base_xpath = '//*[@id="overview"]/div/div/div/div[3]/div/div'.freeze
  
    global_variation = data.at("#{rank_base_xpath}[1]/div/span")
    country_variation = data.at("#{rank_base_xpath}[2]/span")
  
    rank = {
      global: extract_text(data, "#{rank_base_xpath}[1]/div/p"),
      global_variation: extract_text(data, "#{rank_base_xpath}[1]/div/span"),
      global_variation_direction: extract_variation_direction(global_variation),
      
      country: extract_text(data, "#{rank_base_xpath}[2]/p[2]"),
      country_variation: extract_text(data, "#{rank_base_xpath}[2]/span"),
      country_variation_direction: extract_variation_direction(country_variation),
  
      category_pos: extract_text(data, "#{rank_base_xpath}[3]/div[1]/p"),
      category_name: extract_text(data, "#{rank_base_xpath}[3]/div[2]/a"),
    }
  end

  def extract_visits(data)
    visits_base_xpath = '//*[@id="overview"]/div/div/div/div[4]/div[2]/div'.freeze
  
    data = {
      total: extract_text(data, "#{visits_base_xpath}[1]/p[2]"),
      bounce_rate: extract_text(data, "#{visits_base_xpath}[2]/p[2]"),
      pages_per_visit: extract_text(data, "#{visits_base_xpath}[3]/p[2]"),
      avg_duration: extract_text(data, "#{visits_base_xpath}[4]/p[2]"),
    }
  end
  
  def extract_traffic_rank(data)
    alike_base_xpath = '[@id="ranking"]/div/div/div[2]/div[2]/div/div/div'.freeze
  
    current_month = data.xpath('//*[@id="highcharts-7wjwe4y-0"]/div[2]/span/div/div/strong').text
  
    similarly_sites = {
      two_above: {
        pos: extract_text(data, "//*#{alike_base_xpath}[1]/span[1]"),
        domain: extract_text(data, "//*#{alike_base_xpath}[1]/span[3]")
      },
      one_above: {
        pos: extract_text(data, "//*#{alike_base_xpath}[2]/span[1]"),
        domain: extract_text(data, "//*#{alike_base_xpath}[2]/span[3]")
      },
      one_below: {
        pos: extract_text(data, "//*#{alike_base_xpath}[4]/span[1]"),
        domain: extract_text(data, "//*#{alike_base_xpath}[4]/span[3]")
      },
      two_below: {
        pos: extract_text(data, "//*#{alike_base_xpath}[5]/span[1]"),
        domain: extract_text(data, "//*#{alike_base_xpath}[5]/span[3]")
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
      },
      category: {
        # TODO
      },

      # /html/body/div[1]/div/main/div/div/div[2]/section/div/div/div[2]/div[2]/div/div/div[1]/span[3]
      # /html/body/div[1]/div/main/div/div/div[2]/section/div/div/div[2]/div[2]/div/div/div[1]/span[3]
    }
  end

  def extract_top_countries(data)
    top_co_base_xpath = '//*[@id="geography"]/div/div/div[2]/div[2]/div/div'.freeze
    top_countries = {}
  
    (1..5).each do |i|
      top_countries["position_#{i}"] = {
        name: extract_text(data, "#{top_co_base_xpath}[#{i}]/div[2]/a"),
        percent: extract_text(data, "#{top_co_base_xpath}[#{i}]/div[2]/div/span[1]")
      }
    end
  
    others_index = 6
    top_countries[:others] = {
      name: extract_text(data, "#{top_co_base_xpath}[#{others_index}]/div[2]/span"),
      percent: extract_text(data, "#{top_co_base_xpath}[#{others_index}]/div[2]/div/span[1]")
    }
  
    top_countries
  end

  def extract_composition(data)
    composition_base_xpath = '//*[@id="demographics"]/div/div/div[2]/div[2]/ul/li'.freeze
    age_base_xpath = '/html/body/div[1]/div/main/div/div/div[3]/section[3]/div/div/div[2]/div[1]/div/div/div/svg/g'.freeze
    composition = {
      gender: [],
      age: []
    }
  
    (1..2).each do |i|
      composition[:gender] << {
        name: extract_text(data, "#{composition_base_xpath}[#{i}]/span[1]"),
        percent: extract_text(data, "#{composition_base_xpath}[#{i}]/span[2]")
      }
    end

    (1..6).each do |i|
      composition[:age] << {
        range: extract_text(data, "#{age_base_xpath}[7]/text[#{i}]"),
        percent: extract_text(data, "#{age_base_xpath}[6]/g[#{i}]/text/tspan")
      }
    end
  
    composition
  end

  def extract_target_audience(data)
    base_xpath = "//*[@id='interests']/div/div/div[2]/div".freeze
    
    audience = {
      top_categories: [],
      other_visited_sites: [],
      top_topics: [],
    }
  
    (1..5).each do |i|
      audience[:top_categories] << extract_text(data, "#{base_xpath}[1]/div[2]/span[#{i}]")
    end

    (1..5).each do |i|
      audience[:other_visited_sites] << extract_text(data, "#{base_xpath}[2]/div/a[#{i}]/span[2]")
    end

    (1..5).each do |i|
      audience[:top_topics] << extract_text(data, "#{base_xpath}[3]/div[2]/span[#{i}]")
    end
  
    audience
  end

  def extract_competitors(data)
    base_xpath = '//*[@id="competitors"]/div/div/div[2]/div/div[2]/div'.freeze

    competitors = []
  
    (1..10).each do |i|
      site = extract_text(data, "#{base_xpath}[#{i}]/span[1]/a/span[2]")

      if !site.nil?
        competitors << {
          site: site,
          affinity: extract_text(data, "#{base_xpath}[#{i}]/span[2]/span"),
          monthly_visits: extract_text(data, "#{base_xpath}[#{i}]/span[3]"),
          category: extract_text(data, "#{base_xpath}[#{i}]/span[4]"),
          category_rank: extract_text(data, "#{base_xpath}[#{i}]/span[5]"),
        }
      end
    end
  
    competitors
  end

  def extract_traffic_source(data)
    channel_base_xpath = '/html/body/div[1]/div/main/div/div/div[5]/section[1]/div/div/div[2]/div[1]/div/div[1]/div'.freeze
    organic_base_xpath = "//*[@id='traffic-sources']/div/div/div[2]/div[2]/div".freeze

    sources = {
      channels: [],
      organic: [],
    }
  
    (1..7).each do |i|
      sources[:channels] << {     
        label: extract_text(data, "#{channel_base_xpath}/div/span[#{i}]/div/span"),
        percent: extract_text(data, "#{channel_base_xpath}/svg/g[6]/g[#{i}]/text/tspan"),
      }
    end

    (1..2).each do |i|
      sources[:organic] << {     
        site: extract_text(data, "#{organic_base_xpath}[#{i}]/div/span[1]"),
        percent: extract_text(data, "#{organic_base_xpath}[#{i}]/span"),
      }
    end

    sources
  end

  def extract_top_keywords(data)
    base_xpath = "//*[@id='keywords']/div/div/div[2]/div/div/div[1]/span".freeze

    keywords = {
      total_keywords: extract_text(data, '//*[@id="keywords"]/div/div/div[2]/div/div/div[3]/div/span[2]'),
      list: [],
    }

    (1..5).each do |i|
      keywords[:list] << {     
        word: extract_text(data, "#{base_xpath}[#{i}]/span[1]/span[1]"),
        quantity: extract_text(data, "#{base_xpath}[#{i}]/span[1]/span[2]"),
        vol: extract_text(data, "#{base_xpath}[#{i}]/span[2]/span[1]"),
        value: extract_text(data, "#{base_xpath}[#{i}]/span[2]/span[2]"),
      }
    end

    keywords
  end

  def extract_referral_traffic(data)
    category_base_xpath = '//*[@id="referrals"]/div/div/div[2]/div[1]/div/div'.freeze
    top_base_xpath = '//*[@id="referrals"]/div/div/div[2]/div[2]/div/div[1]/a'.freeze

    referral = {
      total: extract_text(data, '//*[@id="referrals"]/div/div/div[2]/div[2]/div/div[3]/div/span[2]'),
      category_distribution: [],
      top_referrals: [],
    }

    (1..5).each do |i|
      referral[:category_distribution] << {
        label: extract_text(data, "#{category_base_xpath}[#{i}]/p/span"),
        percent: extract_text(data, "#{category_base_xpath}[#{i}]/span"),
      }
    end

    (1..5).each do |i|
      
      label_xpath = "#{top_base_xpath}[#{i}]/span/span[1]"
      percent_xpath = "#{top_base_xpath}[#{i}]/span/span[2]"
      label_element = data.at_xpath(label_xpath)

      if label_element.nil? || label_element.text.empty?
        label_xpath = "#{top_base_xpath}[#{i}]/span/span[2]"
        percent_xpath = "#{top_base_xpath}[#{i}]/span/span[3]"
      end

      referral[:top_referrals] << {
        label: extract_text(data, label_xpath),
        percent: extract_text(data, percent_xpath),
      }
    end

    referral
  end

  def extract_social_network(data)
    base_xpath = '/html/body/div[1]/div/main/div/div/div[5]/section[5]/div/div/div[2]/div[2]/div[2]/div'.freeze
    social = Array.new()

    (1..6).each_with_index do |_, i|
      social[i] = {
        label: extract_text(data, "#{base_xpath}/div/span[#{i+1}]/div/span[2]"),
        percent: extract_text(data, "#{base_xpath}/svg/g[6]/g[#{i+1}]/text/tspan"),
      }
    end

    social
  end

  def extract_display_advertising(data)
    base_xpath = '//*[@id="display-ads"]/div/div/div[2]/div[1]/div/div[1]/a'.freeze

    publishers = {
      publishers: extract_text(data, '//*[@id="display-ads"]/div/div/div[2]/div[1]/div/div[3]/div[1]/span[2]'),
      ad_network: extract_text(data, '//*[@id="display-ads"]/div/div/div[2]/div[1]/div/div[3]/div[2]/span[2]'),
      top_publishers: [],
    }

    (1..5).each do |i|
      label_xpath = "#{base_xpath}[#{i}]/span/span[1]"
      percent_xpath = "#{base_xpath}[#{i}]/span/span[2]"
      label_element = data.at_xpath(label_xpath)

      if label_element.nil? || label_element.text.empty?
        label_xpath = "#{base_xpath}[#{i}]/span/span[2]"
        percent_xpath = "#{base_xpath}[#{i}]/span/span[3]"
      end

      publishers[:top_publishers] << {
        label: extract_text(data, label_xpath),
        percent: extract_text(data, percent_xpath),
      }
    end

    publishers
  end

  def extract_links_to_others(data)
    outgoing_base_xpath = '//*[@id="outgoing-links"]/div/div/div[2]/div[1]/div/div[4]/a'.freeze
    links_base_xpath = '//*[@id="outgoing-links"]/div/div/div[2]/div[2]/div/div'.freeze

    response = {
      top_outgoing: [],
      category_distribution: [],
    }

    (1..6).each do |i|  
      label_xpath = "#{outgoing_base_xpath}[#{i}]/span/span[1]"
      percent_xpath = "#{outgoing_base_xpath}[#{i}]/span/span[2]"
      label_element = data.at_xpath(label_xpath)

      if label_element.nil? || label_element.text.empty?
        label_xpath = "#{outgoing_base_xpath}[#{i}]/span/span[2]"
        percent_xpath = "#{outgoing_base_xpath}[#{i}]/span/span[3]"
      end

      response[:top_outgoing] << {
        label: extract_text(data, label_xpath),
        percent: extract_text(data, percent_xpath),
      }
    end

    (1..5).each do |i|
      response[:category_distribution] << {
        label: extract_text(data, "#{links_base_xpath}[#{i}]/p/span"),
        percent: extract_text(data, "#{links_base_xpath}[#{i}]/span"),
      }
    end

    response
  end

  def extract_tech_stack(data)
    response = []

    (1..4).each do |i|
      tech = extract_text(data, "//*[@id='technologies']/div/div/div[2]/div/div[#{i}]/div/p")
      if !tech.nil?
        response[i - 1] = tech
      end
    end

    response
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

  def extract_text(data, xpath)
    element = data.at_xpath(xpath)
    element ? element.text : nil
  end
  

end