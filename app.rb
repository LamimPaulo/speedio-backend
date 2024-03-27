require 'sinatra'
require 'json'
require 'securerandom'
require_relative 'scraper'
require_relative 'database'

class ScraperApp < Sinatra::Base
  connector = Database::Connector.new

  post '/salve_info' do
    request_params = JSON.parse(request.body.read)
    url = request_params['url']

    if url.nil? || url.empty?
      return bad_request('O parametro URL é obrigatorio.')
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

    success_response('Scrapping iniciado com sucesso.', { id: job_id })
  end

  post '/get_info' do
    request_params = JSON.parse(request.body.read)
    url = request_params['url']

    if url.nil? || url.empty?
      return bad_request('O parametro URL é obrigatorio.')
    end

    data = connector.find_job_by_url(url)

    if data.nil?
      return not_found('Site indisponivel para consulta no momento.')
    end

    success_response('Consulta realizada com sucesso!', data)
  end

  private

  def bad_request(message)
    status 400
    content_type :json
    { status: 'error', message: message }.to_json
  end

  def not_found(message)
    status 404
    content_type :json
    { status: 'error', message: message }.to_json
  end

  def success_response(message, data)
    status 200
    content_type :json
    { status: 'success', message: message, data: data }.to_json
  end
end

ScraperApp.run!