require 'rspec'
require 'pathname'

APP_ROOT = Pathname.new(File.expand_path('..', __dir__))
$LOAD_PATH.unshift(APP_ROOT.join('app').to_s)
$LOAD_PATH.unshift(APP_ROOT.join('config').to_s)

Dir[File.join(APP_ROOT, 'app/**/*.rb')].sort.each { |file| require file }

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end
end
