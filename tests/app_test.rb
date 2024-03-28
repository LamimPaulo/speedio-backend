require 'minitest/autorun'
require 'rack/test'
require_relative '../app'

class ScraperAppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    ScraperApp
  end

  def test_salve_info_with_valid_url
    post '/salve_info', { url: 'google.com' }.to_json, 'CONTENT_TYPE' => 'application/json'
    assert last_response.created?
    assert_equal 'success', JSON.parse(last_response.body)['status']
    response_data = JSON.parse(last_response.body)['data']
    assert response_data.key?('id'),

    job_id = response_data['id']
    
    assert !job_id.nil?, 'Job ID is nil'

    test_check_id_with_valid_id(job_id)
  end

  def test_salve_info_with_invalid_url
    post '/salve_info', { url: '' }.to_json, 'CONTENT_TYPE' => 'application/json'
    assert_equal 400, last_response.status
    assert_equal 'error', JSON.parse(last_response.body)['status']
  end

  def test_get_info_with_valid_url
    post '/get_info', { url: 'google.com' }.to_json, 'CONTENT_TYPE' => 'application/json'
    assert last_response.ok?
    assert_equal 'success', JSON.parse(last_response.body)['status']
  end

  def test_get_info_with_invalid_url
    post '/get_info', { url: 'invalidurl.com' }.to_json, 'CONTENT_TYPE' => 'application/json'
    assert_equal 404, last_response.status
    assert_equal 'error', JSON.parse(last_response.body)['status']
  end

  def test_check_id_with_invalid_id
    post '/check_id', { id: '0' }.to_json, 'CONTENT_TYPE' => 'application/json'
    assert_equal 404, last_response.status
    assert_equal 'error', JSON.parse(last_response.body)['status']
  end

  private 

  def test_check_id_with_valid_id(job_id)
    post '/check_id', { id: job_id }.to_json, 'CONTENT_TYPE' => 'application/json'
    assert last_response.ok?
    assert_equal 'success', JSON.parse(last_response.body)['status']
  end
end
