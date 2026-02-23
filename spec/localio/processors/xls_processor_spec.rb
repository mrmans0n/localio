require 'localio/term'
require 'localio/string_helper'
require 'localio/processors/xls_processor'

RSpec.describe XlsProcessor do
  let(:data) do
    {
      [0, 0] => '[key]',    [0, 1] => '*en',  [0, 2] => 'es',             [0, 3] => 'fr',
      [1, 0] => 'app_name', [1, 1] => 'My App', [1, 2] => 'Mi Aplicación', [1, 3] => 'Mon Application',
      [2, 0] => 'greeting', [2, 1] => 'Hello',  [2, 2] => 'Hola',          [2, 3] => 'Bonjour',
      [3, 0] => '[end]',    [3, 1] => '',       [3, 2] => '',              [3, 3] => '',
    }
  end

  let(:worksheet) do
    ws = double('worksheet')
    allow(ws).to receive(:[]) { |row, col| data[[row, col]].to_s }
    allow(ws).to receive(:row_count).and_return(3)
    allow(ws).to receive(:column_count).and_return(3)
    ws
  end

  let(:book_double) { double('book') }

  before do
    allow(Spreadsheet).to receive(:client_encoding=)
    allow(Spreadsheet).to receive(:open).and_return(book_double)
    allow(book_double).to receive(:worksheet).with(0).and_return(worksheet)
  end

  let(:options) { { path: 'fake.xls' } }
  let(:platform_options) { {} }

  describe '.load_localizables' do
    subject(:result) { XlsProcessor.load_localizables(platform_options, options) }

    it 'raises ArgumentError when :path is missing' do
      expect { XlsProcessor.load_localizables({}, {}) }
        .to raise_error(ArgumentError, /:path attribute is missing/)
    end

    it 'returns languages en, es, fr' do
      expect(result[:languages].keys).to contain_exactly('en', 'es', 'fr')
    end

    it 'sets en as default language' do
      expect(result[:default_language]).to eq('en')
    end

    it 'returns 2 terms' do
      expect(result[:segments].count).to eq(2)
    end

    it 'parses translations correctly' do
      app_name = result[:segments].find { |t| t.keyword == 'app_name' }
      expect(app_name.values['en']).to eq('My App')
    end

    it 'raises when worksheet is nil' do
      allow(book_double).to receive(:worksheet).and_return(nil)
      expect { XlsProcessor.load_localizables({}, { path: 'fake.xls' }) }
        .to raise_error(RuntimeError, /Unable to retrieve/)
    end
  end
end
