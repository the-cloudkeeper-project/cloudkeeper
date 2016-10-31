require 'simplecov'
require 'yell'
require 'rspec/collection_matchers'
require 'vcr'
require 'json'

SimpleCov.start do
  add_filter '/vendor'
  add_filter '/spec'
end

require 'cloudkeeper'

Dir["#{File.dirname(__FILE__)}/helpers/*.rb"].each { |file| require file }

MOCK_DIR = File.join(File.dirname(__FILE__), 'mock')

RSpec.configure do |config|
  config.color = true
  config.tty = true
  config.order = 'random'
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
