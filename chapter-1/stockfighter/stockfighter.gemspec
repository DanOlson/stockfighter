# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'stockfighter/version'

Gem::Specification.new do |spec|
  spec.name          = "stockfighter"
  spec.version       = Stockfighter::VERSION
  spec.authors       = ["Dan Olson"]
  spec.email         = ["olson_dan@yahoo.com"]

  spec.summary       = %q{Stockfighter utils}
  spec.description   = %q{Tools for playing Starfigher's Stockfigher game}
  spec.homepage      = "http://your-mom.com"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = Dir['lib/**/*.rb']
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"

  spec.add_dependency 'faraday', '>= 0.9.2'
  spec.add_dependency 'eventmachine'
  spec.add_dependency 'websocket-eventmachine-client'
end
