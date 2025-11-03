
require 'bundler/setup'
require 'pathname'

APP_ROOT = Pathname.new(File.expand_path('../', __FILE__))
$LOAD_PATH.unshift(APP_ROOT.to_s)
$LOAD_PATH.unshift(APP_ROOT.join('app').to_s)
$LOAD_PATH.unshift(APP_ROOT.join('config').to_s)

require 'constants'
require 'config/initializers/elastic_connector'
require 'elastic_services/base_service'
require 'elastic_services/mapper'
require 'elastic_services/reader'
require 'elastic_services/writer'
require 'elastic_services/updater'
require 'constants'
require 'services/update_or_create_service'
require 'router'
