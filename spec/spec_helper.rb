require 'tmpdir'
require 'fileutils'
# Load nokogiri eagerly so it is available before any spec file runs.
# Some specs stub $LOADED_FEATURES for google_drive (which also requires
# nokogiri internally); loading nokogiri here first ensures SimpleXlsxReader
# and android_writer can always find the Nokogiri constant.
require 'nokogiri'

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

Dir[File.expand_path('support/**/*.rb', __dir__)].each { |f| require f }

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.disable_monkey_patching!
  config.order = :random
end
