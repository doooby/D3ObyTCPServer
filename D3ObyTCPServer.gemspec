# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'server/version'

Gem::Specification.new do |spec|
  spec.name          = 'd3oby_tcp_server'
  spec.version       = D3ObyTCPServer::VERSION
  spec.authors       = ['doooby']
  spec.email         = ['zelazk.o@email.cz']
  spec.description   = 'viz github'
  spec.summary       = 'viz github'
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split("\n")
  #spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  #spec.test_files    = spec.files.grep(%r{^spec/})
  #spec.require_paths = ["lib"] # it's default

  #spec.add_development_dependency "bundler", "~> 1.3"
  #spec.add_development_dependency "rake"
  #spec.add_development_dependency 'rspec'
end
