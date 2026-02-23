require 'json'
require 'localio/string_helper'
require 'localio/term'
require 'localio/segment'
require 'localio/segments_list_holder'
require 'localio/formatter'
require 'localio/template_handler'
require 'localio/writers/json_writer'

RSpec.describe JsonWriter do
  include_context 'standard terms'

  let(:options) { { default_language: 'en' } }

  describe '.write' do
    it 'creates strings-{lang}.json for each language' do
      Dir.mktmpdir do |tmpdir|
        workdir = File.join(tmpdir, 'work')
        FileUtils.mkdir_p(workdir)
        Dir.chdir(workdir) { JsonWriter.write(languages, terms, tmpdir, :smart, options) }
        expect(File).to exist(File.join(tmpdir, 'strings-en.json'))
        expect(File).to exist(File.join(tmpdir, 'strings-es.json'))
        expect(File).to exist(File.join(tmpdir, 'strings-fr.json'))
      end
    end

    it 'produces valid JSON' do
      Dir.mktmpdir do |tmpdir|
        workdir = File.join(tmpdir, 'work')
        FileUtils.mkdir_p(workdir)
        Dir.chdir(workdir) { JsonWriter.write(languages, terms, tmpdir, :smart, options) }
        content = File.read(File.join(tmpdir, 'strings-en.json'))
        expect { JSON.parse(content) }.not_to raise_error
      end
    end

    it 'includes translation values' do
      Dir.mktmpdir do |tmpdir|
        workdir = File.join(tmpdir, 'work')
        FileUtils.mkdir_p(workdir)
        Dir.chdir(workdir) { JsonWriter.write(languages, terms, tmpdir, :smart, options) }
        data = JSON.parse(File.read(File.join(tmpdir, 'strings-en.json')))
        expect(data['translations']['app_name']).to eq('My App')
      end
    end

    it 'sets correct language in meta' do
      Dir.mktmpdir do |tmpdir|
        workdir = File.join(tmpdir, 'work')
        FileUtils.mkdir_p(workdir)
        Dir.chdir(workdir) { JsonWriter.write(languages, terms, tmpdir, :smart, options) }
        data = JSON.parse(File.read(File.join(tmpdir, 'strings-es.json')))
        expect(data['meta']['language']).to eq('es')
      end
    end
  end
end
