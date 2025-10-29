require 'yaml'
require 'logger'

module ElasticServices
  module Mapper
    include Constants::Elasticsearch

    def mapping(client, index = INDEX_NAME)
      if index == INDEX_NAME
        setup_mapping(client, index)
      else
        raise "Unsupported index: #{index}"
      end
    end

    def parse_mapping
      YAML.load_file(Constants::MAPPING_PLACE)
    rescue StandardError => e
      Logger.new($stdout).error("Error parsing mapping file: #{e.inspect}")
      nil
    end

    def parse_settings
      YAML.load_file(Constants::SETTINGS_PLACE)
    rescue StandardError => e
      Logger.new($stdout).error("Error parsing settings file: #{e.inspect}")
      {}
    end

    def setup_mapping(client, index)
      mapping = parse_mapping
      raise "Unsupported mapping structure" unless mapping.is_a?(Hash) && mapping.key?("properties")

      client.indices.put_mapping(index: index, body: { properties: mapping["properties"] })
    end
  end
end