require 'localio/term'
require 'localio/string_helper'
require 'localio/processors/csv_processor'

RSpec.describe CsvProcessor do
  let(:fixture_path) { File.expand_path('../../../fixtures/sample.csv', __FILE__) }
  let(:platform_options) { {} }
  let(:options) { { path: fixture_path } }

  describe '.load_localizables' do
    subject(:result) { CsvProcessor.load_localizables(platform_options, options) }

    it 'returns languages en, es, fr' do
      expect(result[:languages].keys).to contain_exactly('en', 'es', 'fr')
    end

    it 'sets en as default language (marked with *)' do
      expect(result[:default_language]).to eq('en')
    end

    it 'returns 8 terms between [key] and [end]' do
      expect(result[:segments].count).to eq(8)
    end

    it 'parses term keywords correctly' do
      keywords = result[:segments].map(&:keyword)
      expect(keywords).to include('app_name', 'greeting', '[comment]', '[init-node]', '[end-node]')
    end

    it 'parses translations for each language' do
      app_name = result[:segments].find { |t| t.keyword == 'app_name' }
      expect(app_name.values['en']).to eq('My App')
      expect(app_name.values['es']).to eq('Mi Aplicación')
      expect(app_name.values['fr']).to eq('Mon Application')
    end

    it 'identifies comment rows' do
      comment = result[:segments].find { |t| t.keyword == '[comment]' }
      expect(comment.is_comment?).to be true
    end

    it 'raises ArgumentError when :path is missing' do
      expect { CsvProcessor.load_localizables({}, {}) }
        .to raise_error(ArgumentError, /:path attribute is missing/)
    end

    it 'raises IndexError when [key] marker is missing' do
      Dir.mktmpdir do |tmpdir|
        path = File.join(tmpdir, 'bad.csv')
        File.write(path, "no,key,row\ndata,here,\n[end],,,\n")
        expect { CsvProcessor.load_localizables({}, { path: path }) }
          .to raise_error(IndexError, /Could not find any \[key\]/)
      end
    end

    it 'raises IndexError when [end] marker is missing' do
      Dir.mktmpdir do |tmpdir|
        path = File.join(tmpdir, 'bad.csv')
        File.write(path, "title,,,\n[key],*en,es,\ndata,val,val,\n")
        expect { CsvProcessor.load_localizables({}, { path: path }) }
          .to raise_error(IndexError, /Could not find any \[end\]/)
      end
    end

    context 'with override_default option' do
      let(:platform_options) { { override_default: 'es' } }

      it 'uses the overridden default language' do
        expect(result[:default_language]).to eq('es')
      end
    end

    context 'with avoid_lang_downcase option' do
      let(:tmpdir) { Dir.mktmpdir }
      let(:options) do
        path = File.join(tmpdir, 'upper.csv')
        File.write(path, "Title,,,\n[key],*EN,ES,FR\napp_name,My App,Mi App,Mon App\n[end],,,\n")
        { path: path }
      end
      let(:platform_options) { { avoid_lang_downcase: true } }

      after { FileUtils.rm_rf(tmpdir) }

      it 'preserves language case' do
        expect(result[:languages].keys).to contain_exactly('EN', 'ES', 'FR')
      end
    end
  end
end
