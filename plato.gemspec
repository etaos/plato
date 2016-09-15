# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'plato/version'

Gem::Specification.new do |spec|
  spec.name          = "plato"
  spec.version       = Plato::VERSION
  spec.authors       = ["Michel Megens"]
  spec.email         = ["dev@bietje.net"]

  spec.summary       = %q{ETA/OS scaffolder}
  spec.description   = %q{Plato generates ETA/OS applications with a single command.}
  spec.homepage      = "http://bietje.net/plato"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubyzip", ">= 1.0.0"
end