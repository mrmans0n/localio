# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'localio/version'

Gem::Specification.new do |spec|
  spec.name          = "localio"
  spec.version       = Localio::VERSION
  spec.authors       = ["Nacho Lopez"]
  spec.email         = ["nacho@nlopez.io"]
  spec.description   = %q{Automatic Localizable file generation based on Google Drive spreadsheets}
  spec.summary       = %q{Automatic Localizable file generation for multiple type of files, like Android string.xml, Xcode Localizable.strings, JSON files, YAML files, etc. using Google Drive spreadsheets as base.}
  spec.homepage      = "http://nlopez.io"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rspec"

  spec.required_ruby_version = ">= 1.9.2"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  
  spec.add_dependency "micro-optparse", "~> 1.1.5"
  spec.add_dependency "google_drive", "~> 0.3.6"
  
end
