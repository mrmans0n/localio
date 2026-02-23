require 'localio/string_helper'
require 'localio/term'
require 'localio/segment'
require 'localio/segments_list_holder'
require 'localio/formatter'
require 'localio/template_handler'
require 'localio/writers/rails_writer'

RSpec.describe RailsWriter do
  include_context 'standard terms'

  let(:options) { { default_language: 'en' } }

  describe '.write' do
    it 'creates {lang}.yml for each language' do
      Dir.mktmpdir do |tmpdir|
        workdir = File.join(tmpdir, 'work')
        FileUtils.mkdir_p(workdir)
        Dir.chdir(workdir) { RailsWriter.write(languages, terms, tmpdir, :smart, options) }
        expect(File).to exist(File.join(tmpdir, 'en.yml'))
        expect(File).to exist(File.join(tmpdir, 'es.yml'))
        expect(File).to exist(File.join(tmpdir, 'fr.yml'))
      end
    end

    it 'starts YAML with the language key' do
      Dir.mktmpdir do |tmpdir|
        workdir = File.join(tmpdir, 'work')
        FileUtils.mkdir_p(workdir)
        Dir.chdir(workdir) { RailsWriter.write(languages, terms, tmpdir, :smart, options) }
        content = File.read(File.join(tmpdir, 'en.yml'))
        expect(content).to include('en:')
        expect(content).to include('app_name: "My App"')
      end
    end

    it 'renders comment rows as YAML comments' do
      Dir.mktmpdir do |tmpdir|
        workdir = File.join(tmpdir, 'work')
        FileUtils.mkdir_p(workdir)
        Dir.chdir(workdir) { RailsWriter.write(languages, terms, tmpdir, :smart, options) }
        content = File.read(File.join(tmpdir, 'en.yml'))
        expect(content).to include('# Section General')
      end
    end
  end
end
