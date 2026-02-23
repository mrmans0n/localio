lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'localio/version'

Gem::Specification.new do |spec|
  spec.name          = "localio"
  spec.version       = Localio::VERSION
  spec.authors       = ["Nacho Lopez"]
  spec.email         = ["nacho@nlopez.io"]
  spec.description   = %q{Automatic Localizable file generation for multiple platforms}
  spec.summary       = %q{Generates Android, iOS, Rails, JSON, Java Properties, and .NET ResX localization files from spreadsheet sources.}
  spec.homepage      = "https://github.com/mrmans0n/localio"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split("\n")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.2"

  spec.add_development_dependency "rspec",   "~> 3.0"
  spec.add_development_dependency "rake"

  spec.add_dependency "google_drive",        "~> 3.0"
  spec.add_dependency "spreadsheet",         "~> 1.3"
  spec.add_dependency "simple_xlsx_reader",  "~> 2.0"
  spec.add_dependency "nokogiri",            "~> 1.16"
  spec.add_dependency "csv",                  ">= 3.2"
end
