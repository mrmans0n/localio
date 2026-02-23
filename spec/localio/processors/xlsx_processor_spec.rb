# simple_xlsx_reader transitively loads nokogiri, whose native extension is
# compiled for x86_64 and fails to dlopen on this arm64 host.  We prevent the
# real gem files from ever being evaluated by:
#   1. Defining a minimal SimpleXlsxReader stub constant before anything tries
#      to reference it.
#   2. Pre-populating $LOADED_FEATURES with the absolute gem paths so that
#      every subsequent `require 'simple_xlsx_reader'` (including the one at
#      the top of xlsx_processor.rb) is treated as already loaded.
# All runtime calls to SimpleXlsxReader.open are intercepted by RSpec doubles.

module SimpleXlsxReader
  def self.open(_path); end
end

begin
  _slim_base = '/Volumes/Workspace/localio/.worktrees/modernization/' \
               'vendor/bundle/ruby/2.6.0/gems/simple_xlsx_reader-1.0.5/lib'
  _nok_base  = '/Volumes/Workspace/localio/.worktrees/modernization/' \
               'vendor/bundle/ruby/2.6.0/gems/nokogiri-1.13.10-x86_64-darwin/lib'
  [
    "#{_slim_base}/simple_xlsx_reader.rb",
    "#{_slim_base}/simple_xlsx_reader/version.rb",
    "#{_nok_base}/nokogiri.rb",
    "#{_nok_base}/nokogiri/extension.rb",
  ].each { |f| $LOADED_FEATURES << f unless $LOADED_FEATURES.include?(f) }
end

require 'localio/term'
require 'localio/string_helper'
require 'localio/processors/xlsx_processor'

RSpec.describe XlsxProcessor do
  let(:rows) do
    [
      ['Title', nil, nil, nil],
      ['[key]', '*en', 'es', 'fr'],
      ['[comment]', 'Section General', 'Section General', 'Section General'],
      ['app_name', 'My App', 'Mi Aplicación', 'Mon Application'],
      ['greeting', 'Hello', 'Hola', 'Bonjour'],
      ['[end]', nil, nil, nil],
    ]
  end

  let(:sheet_double) { double('sheet', rows: rows) }
  let(:book_double) { double('book', sheets: [sheet_double]) }

  before { allow(SimpleXlsxReader).to receive(:open).and_return(book_double) }

  let(:options) { { path: 'fake.xlsx', sheet: 0 } }
  let(:platform_options) { {} }

  describe '.load_localizables' do
    subject(:result) { XlsxProcessor.load_localizables(platform_options, options) }

    it 'raises ArgumentError when :path is missing' do
      expect { XlsxProcessor.load_localizables({}, {}) }
        .to raise_error(ArgumentError, /:path attribute is missing/)
    end

    it 'returns languages en, es, fr' do
      expect(result[:languages].keys).to contain_exactly('en', 'es', 'fr')
    end

    it 'sets en as default language' do
      expect(result[:default_language]).to eq('en')
    end

    it 'returns 3 terms' do
      expect(result[:segments].count).to eq(3)
    end

    it 'parses translations correctly' do
      app_name = result[:segments].find { |t| t.keyword == 'app_name' }
      expect(app_name.values['en']).to eq('My App')
      expect(app_name.values['es']).to eq('Mi Aplicación')
    end

    it 'raises when sheet is nil' do
      named_book = double('book', sheets: [])
      allow(SimpleXlsxReader).to receive(:open).and_return(named_book)
      allow(named_book).to receive(:sheets).and_return([])
      expect { XlsxProcessor.load_localizables({}, { path: 'fake.xlsx', sheet: 'Missing' }) }
        .to raise_error(RuntimeError, /Unable to retrieve/)
    end
  end
end
