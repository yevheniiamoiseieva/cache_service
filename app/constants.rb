module Constants
  ROOT_DIR = File.expand_path('../../', __FILE__).freeze

  MAPPING_PLACE = File.join(ROOT_DIR, 'config', 'elastic', 'mapping.yaml').freeze
  SETTINGS_PLACE = File.join(ROOT_DIR, 'config', 'elastic', 'elasticsearch.yaml').freeze

  module Elasticsearch
    INDEX_NAME = ENV.fetch('ELASTIC_INDEX_NAME', 'cache_events_v1').freeze
    INDEX_ALIAS = ENV.fetch('ELASTIC_INDEX_ALIAS', 'cache_events').freeze
  end
end