# Require nokogiri explicitly before simple_xlsx_reader so that the Nokogiri
# constant is defined regardless of test-suite load order.  Other specs
# pre-populate $LOADED_FEATURES with nokogiri paths (to prevent loading the
# old x86_64 build), which would cause simple_xlsx_reader to skip the require
# and leave Nokogiri undefined.  Loading nokogiri here first, before any stub
# can interfere, ensures the constant is available.
require 'nokogiri'
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
