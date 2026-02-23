# Stub out nokogiri (vendored x86_64 build cannot dlopen on this arm64 host)
begin
  _nok_base = '/Volumes/Workspace/localio/.worktrees/modernization/' \
              'vendor/bundle/ruby/2.6.0/gems/nokogiri-1.13.10-x86_64-darwin/lib'
  [
    "#{_nok_base}/nokogiri.rb",
    "#{_nok_base}/nokogiri/extension.rb",
  ].each { |f| $LOADED_FEATURES << f unless $LOADED_FEATURES.include?(f) }
end

require 'json'
require 'localio/string_helper'
require 'localio/term'
require 'localio/segment'
require 'localio/segments_list_holder'
require 'localio/filter'
require 'localio/formatter'
require 'localio/template_handler'
require 'localio/processors/csv_processor'
require 'localio/writers/android_writer'
require 'localio/writers/json_writer'

RSpec.describe 'Localio pipeline' do
  let(:fixture_path) { File.expand_path('fixtures/sample.csv', __dir__) }

  it 'processes CSV and writes Android strings.xml with correct transformations' do
    Dir.mktmpdir do |tmpdir|
      workdir = File.join(tmpdir, 'work')
      FileUtils.mkdir_p(workdir)
      Dir.chdir(workdir) do
        result = CsvProcessor.load_localizables({}, { path: fixture_path })
        AndroidWriter.write(result[:languages], result[:segments], tmpdir, :smart,
                            { default_language: result[:default_language] })

        content = File.read(File.join(tmpdir, 'values', 'strings.xml'))
        expect(content).to include('<string name="app_name">My App</string>')
        expect(content).to include('&amp; Jerry')
        expect(content).to include('Wait…')
        expect(content).to include('%s world')
        expect(content).to include('<!-- Section General -->')
      end
    end
  end

  it 'processes CSV and writes valid JSON with correct content' do
    Dir.mktmpdir do |tmpdir|
      workdir = File.join(tmpdir, 'work')
      FileUtils.mkdir_p(workdir)
      Dir.chdir(workdir) do
        result = CsvProcessor.load_localizables({}, { path: fixture_path })
        JsonWriter.write(result[:languages], result[:segments], tmpdir, :smart,
                         { default_language: result[:default_language] })

        data = JSON.parse(File.read(File.join(tmpdir, 'strings-en.json')))
        expect(data['translations']['app_name']).to eq('My App')
        expect(data['meta']['language']).to eq('en')
      end
    end
  end

  it 'applies only filter before writing' do
    result = CsvProcessor.load_localizables({}, { path: fixture_path })
    filtered = Filter.apply_filter(result[:segments], { keys: 'app_' }, nil)
    expect(filtered.map(&:keyword)).to eq(['app_name'])
  end

  it 'applies except filter before writing' do
    result = CsvProcessor.load_localizables({}, { path: fixture_path })
    filtered = Filter.apply_filter(result[:segments], nil, { keys: 'dots_|ampersand_' })
    expect(filtered.map(&:keyword)).not_to include('dots_test', 'ampersand_test')
  end
end
