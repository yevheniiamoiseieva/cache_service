module Constants
  ROOT_DIR = File.expand_path('../../', __FILE__).freeze

  MAPPING_PLACE = File.join(ROOT_DIR, 'config', 'mapping.yaml').freeze
  SETTINGS_PLACE = File.join(ROOT_DIR, 'config', 'elasticsearch.yml').freeze

  module Elasticsearch
    INDEX_NAME = 'cache_events_v1'.freeze
    INDEX_ALIAS = 'cache_events'.freeze
  end
end