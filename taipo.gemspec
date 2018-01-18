# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'taipo/version'

Gem::Specification.new do |spec|
  spec.name          = "taipo"
  spec.version       = Taipo::VERSION
  spec.authors       = ["Michael Camilleri"]
  spec.email         = ["dev@inqk.net"]

  spec.summary       = %q{A simple library for checking the types of variables.}
  spec.description   = %q{Taipo provides a simple way to check your variables are what you think they are. With an easy to use syntax you can call a single method and pass expressive type definitions.}
  spec.homepage      = "https://github.com/pyrmont/taipo/"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.10.3"
  spec.add_development_dependency "minitest-reporters", "~> 1.1.19"
  spec.add_development_dependency "shoulda-context", "~> 1.2.0"
  spec.add_development_dependency "yard", "~> 0.9.12"
end
