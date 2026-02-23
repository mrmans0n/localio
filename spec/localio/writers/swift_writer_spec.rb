require 'localio/string_helper'
require 'localio/term'
require 'localio/segment'
require 'localio/segments_list_holder'
require 'localio/formatter'
require 'localio/template_handler'
require 'localio/writers/swift_writer'

RSpec.describe SwiftWriter do
  include_context 'standard terms'

  let(:options) { { default_language: 'en' } }

  describe '.write' do
    it 'creates Localizable.strings in {lang}.lproj/' do
      Dir.mktmpdir do |tmpdir|
        workdir = File.join(tmpdir, 'work')
        FileUtils.mkdir_p(workdir)
        Dir.chdir(workdir) { SwiftWriter.write(languages, terms, tmpdir, :smart, options) }
        expect(File).to exist(File.join(tmpdir, 'en.lproj', 'Localizable.strings'))
      end
    end

    it 'creates LocalizableConstants.swift by default' do
      Dir.mktmpdir do |tmpdir|
        workdir = File.join(tmpdir, 'work')
        FileUtils.mkdir_p(workdir)
        Dir.chdir(workdir) { SwiftWriter.write(languages, terms, tmpdir, :smart, options) }
        expect(File).to exist(File.join(tmpdir, 'LocalizableConstants.swift'))
      end
    end

    it 'skips LocalizableConstants.swift when create_constants is false' do
      Dir.mktmpdir do |tmpdir|
        workdir = File.join(tmpdir, 'work')
        FileUtils.mkdir_p(workdir)
        Dir.chdir(workdir) { SwiftWriter.write(languages, terms, tmpdir, :smart, options.merge(create_constants: false)) }
        expect(File).not_to exist(File.join(tmpdir, 'LocalizableConstants.swift'))
      end
    end
  end
end
