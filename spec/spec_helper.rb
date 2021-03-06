require 'simplecov'
require 'yell'
require 'rspec/collection_matchers'
require 'vcr'
require 'json'
require 'diffy'

SimpleCov.start do
  add_filter '/vendor'
  add_filter '/spec'
end

Diffy::Diff.default_format = :color

require 'cloudkeeper_grpc'
require 'cloudkeeper'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

MOCK_DIR = File.join(File.dirname(__FILE__), 'mock')

RSpec.configure do |config|
  config.color = true
  config.tty = true
  config.order = 'random'
end

VCR.configure do |config|
  config.cassette_library_dir = File.join(MOCK_DIR, 'cassettes')
  config.hook_into :webmock
  config.configure_rspec_metadata!
end

Yell.new :file, '/dev/null', name: Object, level: 'error', format: Yell::DefaultFormat
# Yell.new :stdout, :name => Object, :level => 'debug', :format => Yell::DefaultFormat
Object.send :include, Yell::Loggable

def load_file(filename, options = {})
  symbolize = options[:symbolize]

  hash = JSON.parse(File.read(File.join(MOCK_DIR, 'structures', filename)))
  hash.deep_symbolize_keys! if symbolize

  hash
end
