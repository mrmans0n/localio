require 'localio/string_helper'
require 'localio/term'
require 'localio/segment'
require 'localio/segments_list_holder'
require 'localio/formatter'
require 'localio/template_handler'
require 'localio/writers/resx_writer'

RSpec.describe ResXWriter do
  include_context 'standard terms'

  let(:options) { { default_language: 'en' } }

  describe '.write' do
    it 'creates Resources.resx for the default language' do
      Dir.mktmpdir do |tmpdir|
        workdir = File.join(tmpdir, 'work')
        FileUtils.mkdir_p(workdir)
        Dir.chdir(workdir) { ResXWriter.write(languages, terms, tmpdir, :smart, options) }
        expect(File).to exist(File.join(tmpdir, 'Resources.resx'))
      end
    end

    it 'creates Resources.{lang}.resx for non-default languages' do
      Dir.mktmpdir do |tmpdir|
        workdir = File.join(tmpdir, 'work')
        FileUtils.mkdir_p(workdir)
        Dir.chdir(workdir) { ResXWriter.write(languages, terms, tmpdir, :smart, options) }
        expect(File).to exist(File.join(tmpdir, 'Resources.es.resx'))
        expect(File).to exist(File.join(tmpdir, 'Resources.fr.resx'))
      end
    end

    it 'uses custom resource_file name when specified' do
      Dir.mktmpdir do |tmpdir|
        workdir = File.join(tmpdir, 'work')
        FileUtils.mkdir_p(workdir)
        Dir.chdir(workdir) { ResXWriter.write(languages, terms, tmpdir, :smart, options.merge(resource_file: 'Strings')) }
        expect(File).to exist(File.join(tmpdir, 'Strings.resx'))
        expect(File).to exist(File.join(tmpdir, 'Strings.es.resx'))
      end
    end
  end
end
