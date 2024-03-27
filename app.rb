require 'sinatra'
require 'json'
require 'securerandom'
require_relative 'scraper'
require_relative 'database'

connector = Database::Connector.new

get '/' do
  url = params['url']
  "Hello world"
end

post '/salve_info' do
  params = JSON.parse(request.body.read)
  url = params['url']
  
  if !url || url.empty?
    status 400
    content_type :json
    return {
        status: 'error',
        message: 'O parametro URL é obrigatorio.'
    }.to_json
  end

  job_id = SecureRandom.uuid
  connector.insert_job(job_id, 'pending', url)

  Thread.new do
    begin    
        scraper = WebScraper.new(url)
        data = scraper.scrape!
        connector.update_job(job_id, 'completed', data)
    rescue StandardError => e
        connector.update_job(job_id, 'failed', e.message)
    end
  end

  status 201
  content_type :json
  {
    status: 'success',
    message: 'Scrapping iniciado com sucesso.',
    data: {
      id: job_id,
    }
  }.to_json

end

post '/get_info' do
  params = JSON.parse(request.body.read)
  url = params['url']

  if !url || url.empty?
    status 400
    content_type :json
    return {
      status: 'error',
      message: 'O parametro URL é obrigatorio.',
    }.to_json
  end

  data = connector.find_job_by_url(url)
  puts data, data.nil?

  if data.nil?
    status 400
    content_type :json
    return {
      status: 'error',
      message: 'Site indisponivel para consulta no momento.'
  }.to_json
  end


  status 200
  content_type :json
  {
    status: 'success',
    message: 'Consulta realizada com sucesso!',
    data: data
  }.to_json
end
