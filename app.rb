require 'bundler/setup'
require_relative 'app/constants'
require_relative 'app/elastic_connector'
require_relative 'app/elastic_services/mapper'
require_relative 'app/elastic_services/base_service'

require_relative 'app/elastic_services/reader'
require_relative 'app/elastic_services/writer'
require_relative 'app/elastic_services/updater'

require_relative 'app/services/update_or_create_service'
require_relative 'app/router'

ElasticServices::BaseService