require 'dotenv/load'
require 'mongo'

module Database
  class Connector
    def initialize
      @client = Mongo::Client.new(ENV['MONGODB_URI'])
      @collection = @client[:scraping_jobs]
    end

    def insert_job(job_id, status, url)
      @collection.insert_one({ job_id: job_id, url: url, status: status })
    end

    def update_job(job_id, new_status, data)
      @collection.update_one({ job_id: job_id }, { '$set' => { status: new_status, data: data} })
    end

    def find_job_by_id(job_id)
      @collection.find({ job_id: job_id }).first
    end

    def find_job_by_url(url)
      @collection.find({ url: url }).first
    end
  end
end
