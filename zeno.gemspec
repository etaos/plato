# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'zeno/version'

Gem::Specification.new do |spec|
  spec.name          = "zeno"
  spec.version       = Zeno::VERSION
  spec.authors       = ["Michel Megens"]
  spec.email         = ["dev@bietje.net"]

  spec.summary       = %q{ETA/OS scaffolder}
  spec.description   = %q{Zeno generates ETA/OS applications with a single command.}
  spec.homepage      = "http://bietje.net/zeno"

  spec.bindir        = "bin"
  spec.executables   = ['zeno']
  spec.require_paths = ["lib"]
  spec.files = [
    'bin/zeno',
    'lib/zeno.rb',
    'lib/zeno/applicationalreadyexistserror.rb',
    'lib/zeno/filegenerator.rb',
    'lib/zeno/makefile.rb',
    'lib/zeno/scaffolder.rb',
    'lib/zeno/version.rb'
  ]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubyzip", ">= 1.0.0"
end
