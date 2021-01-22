lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cloudkeeper/version'

Gem::Specification.new do |spec|
  spec.name          = 'cloudkeeper'
  spec.version       = Cloudkeeper::VERSION
  spec.authors       = ['Michal Kimle']
  spec.email         = ['kimle.michal@gmail.com']

  spec.summary       = 'Synchronize cloud appliances between AppDB and cloud platforms'
  spec.description   = 'Synchronize cloud appliances between AppDB and cloud platforms'
  spec.homepage      = 'https://github.com/the-cloudkeeper-project/cloudkeeper'
  spec.license       = 'Apache License, Version 2.0'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  # get an array of submodule dirs by executing 'pwd' inside each submodule
  gem_dir = __dir__ + '/'
  `git submodule --quiet foreach --recursive pwd`.split($OUTPUT_RECORD_SEPARATOR).each do |submodule_path|
    Dir.chdir(submodule_path) do
      submodule_relative_path = submodule_path.sub gem_dir, ''
      # issue git ls-files in submodule's directory and
      # prepend the submodule path to create absolute file paths
      `git ls-files`.split($OUTPUT_RECORD_SEPARATOR).each do |filename|
        spec.files << "#{submodule_relative_path}/#{filename}"
      end
    end
  end
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '>= 1.13'
  spec.add_development_dependency 'diffy', '~> 3.1'
  spec.add_development_dependency 'google-protobuf', '~> 3.6.1'
  spec.add_development_dependency 'grpc-tools', '~> 1.14'
  spec.add_development_dependency 'i18n', '~> 1.1.1'
  spec.add_development_dependency 'pry', '~> 0.10'
  spec.add_development_dependency 'public_suffix', '~> 3.0.3'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec', '~> 3.5'
  spec.add_development_dependency 'rspec-collection_matchers', '~> 1.1'
  spec.add_development_dependency 'rubocop', '0.60.0'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.32.0'
  spec.add_development_dependency 'simplecov', '~> 0.12'
  spec.add_development_dependency 'simplecov-html', '~> 0.10.2'
  spec.add_development_dependency 'vcr', '~> 4.0'
  spec.add_development_dependency 'webmock', '~> 3.0'

  spec.add_runtime_dependency 'activesupport', '>= 4.0', '< 6.0'
  spec.add_runtime_dependency 'faraday', '~> 0.11'
  spec.add_runtime_dependency 'grpc', '1.35.0'
  spec.add_runtime_dependency 'mixlib-shellout', '~> 2.2'
  spec.add_runtime_dependency 'settingslogic', '~> 2.0'
  spec.add_runtime_dependency 'thor', '~> 0.19'
  spec.add_runtime_dependency 'tilt', '~> 2.0'
  spec.add_runtime_dependency 'yell', '~> 2.0'
  spec.add_runtime_dependency 'zaru', '~> 0.1'

  spec.required_ruby_version = '>= 2.2.0'
end
