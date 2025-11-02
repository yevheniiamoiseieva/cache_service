require 'logger'
require 'elasticsearch'
require 'constants'
require 'initializers/elastic_connector'
require 'elastic_services/mapper'

module ElasticServices
  class BaseService
    include Constants::Elasticsearch
    extend Mapper

    ALLOWED_PARAMS = %i[client_pool index logger params action per page limit from].freeze

    class << self
      attr_accessor :client_pool, :elastic_logger

      def setup_elastic_client
        @elastic_logger ||= Logger.new($stdout)
        @client_pool ||= ElasticConnector.instance.connection_pool
        find_or_create_index
      rescue StandardError => e
        @elastic_logger.error("Error with client initialization during setup: #{e.inspect}.")
      end

      def create_index!
        client_pool.with { |connection| connection.indices.create(index: INDEX_NAME, body: parse_settings) }
        put_alias!
      rescue StandardError => e
        elastic_logger.error("Error creating index: #{e.inspect}.")
        false
      end

      def update_index!
        client_pool.with { |connection| mapping(connection, INDEX_NAME) }
      rescue StandardError => e
        elastic_logger.error("Error updating index: #{e}.")
        false
      end

      def put_alias!
        client_pool.with { |connection| connection.indices.update_aliases body: { actions: [{ add: { index: INDEX_NAME, alias: INDEX_ALIAS } }] } }
      rescue StandardError => e
        elastic_logger.error("Error with alias: #{e}.")
        false
      end

      def index_exists?
        client_pool.with { |connection| connection&.indices&.exists?(index: INDEX_NAME) }
      end

      def find_or_create_index
        create_index! unless index_exists?
        update_index!
      end

      def call(args)
        setup_elastic_client unless @client_pool

        hash_params = args.select { |key, _value| ALLOWED_PARAMS.include? key }
        new(hash_params).public_send(hash_params[:action]&.to_sym)
      end
    end

    attr_accessor :client_pool, :index, :logger, :params, :size, :from

    def initialize(args)
      self.client_pool = self.class.client_pool
      self.index = INDEX_NAME
      self.logger = self.class.elastic_logger
      self.params = args[:params] || {}
      self.size = obtain_size(args)
      self.from = obtain_from(args)
    end

    def obtain_size(hash)
      size = (hash[:size] || hash[:limit] || hash[:per]).to_i
      size.positive? ? size : 100
    end

    def obtain_from(hash)
      return hash[:from].to_i if hash[:from]&.to_i
      return 0 unless hash[:page]&.to_i && hash[:per]&.to_i

      current_page = (hash[:page].to_i - 1).to_i
      (current_page * hash[:per].to_i)
    end

    def log_error(error)
      logger.error(error)
      nil
    end
  end
end