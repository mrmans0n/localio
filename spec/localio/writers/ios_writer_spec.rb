require 'localio/string_helper'
require 'localio/term'
require 'localio/segment'
require 'localio/segments_list_holder'
require 'localio/formatter'
require 'localio/template_handler'
require 'localio/writers/ios_writer'

RSpec.describe IosWriter do
  include_context 'standard terms'

  let(:options) { { default_language: 'en' } }

  describe '.write' do
    it 'creates Localizable.strings in {lang}.lproj/ for each language' do
      Dir.mktmpdir do |tmpdir|
        workdir = File.join(tmpdir, 'work')
        FileUtils.mkdir_p(workdir)
        Dir.chdir(workdir) { IosWriter.write(languages, terms, tmpdir, :smart, options) }
        expect(File).to exist(File.join(tmpdir, 'en.lproj', 'Localizable.strings'))
        expect(File).to exist(File.join(tmpdir, 'es.lproj', 'Localizable.strings'))
      end
    end

    it 'creates LocalizableConstants.h by default' do
      Dir.mktmpdir do |tmpdir|
        workdir = File.join(tmpdir, 'work')
        FileUtils.mkdir_p(workdir)
        Dir.chdir(workdir) { IosWriter.write(languages, terms, tmpdir, :smart, options) }
        expect(File).to exist(File.join(tmpdir, 'LocalizableConstants.h'))
      end
    end

    it 'skips LocalizableConstants.h when create_constants is false' do
      Dir.mktmpdir do |tmpdir|
        workdir = File.join(tmpdir, 'work')
        FileUtils.mkdir_p(workdir)
        Dir.chdir(workdir) { IosWriter.write(languages, terms, tmpdir, :smart, options.merge(create_constants: false)) }
        expect(File).not_to exist(File.join(tmpdir, 'LocalizableConstants.h'))
      end
    end

    it 'renders comment rows as line comments' do
      Dir.mktmpdir do |tmpdir|
        workdir = File.join(tmpdir, 'work')
        FileUtils.mkdir_p(workdir)
        Dir.chdir(workdir) { IosWriter.write(languages, terms, tmpdir, :smart, options) }
        content = File.read(File.join(tmpdir, 'en.lproj', 'Localizable.strings'))
        expect(content).to include('// Section General')
      end
    end

    it 'includes translation values' do
      Dir.mktmpdir do |tmpdir|
        workdir = File.join(tmpdir, 'work')
        FileUtils.mkdir_p(workdir)
        Dir.chdir(workdir) { IosWriter.write(languages, terms, tmpdir, :smart, options) }
        content = File.read(File.join(tmpdir, 'en.lproj', 'Localizable.strings'))
        expect(content).to include('My App')
      end
    end
  end
end
