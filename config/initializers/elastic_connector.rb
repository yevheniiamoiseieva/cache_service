require 'elasticsearch'
require 'connection_pool'
require 'singleton'

class ElasticConnector
  include Singleton
  attr_reader :connection_pool

  def initialize
    elastic_url = ENV.fetch('ELASTICSEARCH_URL')
    pool_size = ENV.fetch('ELASTIC_POOL_SIZE').to_i
    pool_timeout = ENV.fetch('ELASTIC_POOL_TIMEOUT').to_i

    @connection_pool = ConnectionPool.new(size: pool_size, timeout: pool_timeout) do
      Elasticsearch::Client.new(url: elastic_url, log: true)
    end
  end

  def self.connection_pool
    instance.connection_pool
  end
end