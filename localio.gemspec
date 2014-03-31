# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'localio/version'

Gem::Specification.new do |spec|
  spec.name          = "localio"
  spec.version       = Localio::VERSION
  spec.authors       = ["Nacho Lopez"]
  spec.email         = ["nacho@nlopez.io"]
  spec.description   = %q{Automatic Localizable file generation for multiple platforms (Rails YAML, Android, Java Properties, iOS, JSON)}
  spec.summary       = %q{Automatic Localizable file generation for multiple type of files, like Android string.xml, Xcode Localizable.strings, JSON files, Rails YAML files, Java properties, etc. reading from Google Drive and Excel spreadsheets as base.}
  spec.homepage      = "http://github.com/mrmans0n/localio"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  
  spec.executables << "localize"

  spec.add_development_dependency "rspec"

  spec.required_ruby_version = ">= 1.9.2"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  
  spec.add_dependency "micro-optparse", "~> 1.1.5"
  spec.add_dependency "google_drive", "~> 0.3.6"
  spec.add_dependency "spreadsheet", "~> 0.8.9"
  spec.add_dependency "simple_xlsx_reader", "~> 0.9.8"
  spec.add_dependency "nokogiri", "~> 1.6.1"
end
