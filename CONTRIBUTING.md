Contributing
============

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Dependency security

Install the bundle, audit it against the current Ruby Advisory Database, and run the
checks before submitting dependency updates:

```sh
bundle install
bundle exec bundle-audit check --update
bundle exec rspec
bundle exec rake build
```

CI runs the audit, tests, and gem build on every supported Ruby version. The release
workflow also audits the bundle before publishing to RubyGems. Do not ignore or
dismiss advisories instead of updating the affected dependency.

Update `Gemfile.lock` for all tracked platforms. If a vulnerable version is still
allowed by a runtime dependency in `localio.gemspec`, raise its minimum version as
well. RubyGems consumers resolve dependencies from the gemspec, not this repository's
lockfile. Regression specs in `spec/localio/dependencies_spec.rb` protect these
minimum safe versions.