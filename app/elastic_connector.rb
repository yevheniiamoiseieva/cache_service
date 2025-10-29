require 'elasticsearch'
require 'connection_pool'

class ElasticConnector
  CONNECTION_POOL = begin
                      elastic_url = ENV.fetch('ELASTICSEARCH_URL', 'http://es:9200')

                      ConnectionPool.new(size: 5, timeout: 5) do
                        Elasticsearch::Client.new(url: elastic_url, log: true)
                      end
                    end

  def self.connection_pool
    CONNECTION_POOL
  end
end
