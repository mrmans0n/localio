require 'localio/string_helper'
require 'localio/term'
require 'localio/segment'
require 'localio/segments_list_holder'
require 'localio/formatter'
require 'localio/template_handler'
require 'localio/writers/java_properties_writer'

RSpec.describe JavaPropertiesWriter do
  include_context 'standard terms'

  let(:options) { { default_language: 'en' } }

  describe '.write' do
    it 'creates language_{lang}.properties for each language' do
      Dir.mktmpdir do |tmpdir|
        workdir = File.join(tmpdir, 'work')
        FileUtils.mkdir_p(workdir)
        Dir.chdir(workdir) { JavaPropertiesWriter.write(languages, terms, tmpdir, :smart, options) }
        expect(File).to exist(File.join(tmpdir, 'language_en.properties'))
        expect(File).to exist(File.join(tmpdir, 'language_es.properties'))
      end
    end

    it 'includes translation values' do
      Dir.mktmpdir do |tmpdir|
        workdir = File.join(tmpdir, 'work')
        FileUtils.mkdir_p(workdir)
        Dir.chdir(workdir) { JavaPropertiesWriter.write(languages, terms, tmpdir, :smart, options) }
        content = File.read(File.join(tmpdir, 'language_en.properties'))
        expect(content).to include('My App')
      end
    end
  end
end
