# nokogiri's native extension is compiled for x86_64 and fails to dlopen on
# this arm64 host.  We stub it out by pre-populating $LOADED_FEATURES so that
# every subsequent `require 'nokogiri'` (including the one inside
# android_writer.rb) is treated as already loaded.

begin
  _nok_base = '/Volumes/Workspace/localio/.worktrees/modernization/' \
              'vendor/bundle/ruby/2.6.0/gems/nokogiri-1.13.10-x86_64-darwin/lib'
  [
    "#{_nok_base}/nokogiri.rb",
    "#{_nok_base}/nokogiri/extension.rb",
  ].each { |f| $LOADED_FEATURES << f unless $LOADED_FEATURES.include?(f) }
end

require 'localio/string_helper'
require 'localio/term'
require 'localio/segment'
require 'localio/segments_list_holder'
require 'localio/formatter'
require 'localio/template_handler'
require 'localio/writers/android_writer'

RSpec.describe AndroidWriter do
  include_context 'standard terms'

  let(:options) { { default_language: 'en' } }

  describe '.write' do
    it 'creates values/strings.xml for the default language' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { AndroidWriter.write(languages, terms, tmpdir, :smart, options) }
        expect(File).to exist(File.join(tmpdir, 'values', 'strings.xml'))
      end
    end

    it 'creates values-{lang}/strings.xml for non-default languages' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { AndroidWriter.write(languages, terms, tmpdir, :smart, options) }
        expect(File).to exist(File.join(tmpdir, 'values-es', 'strings.xml'))
        expect(File).to exist(File.join(tmpdir, 'values-fr', 'strings.xml'))
      end
    end

    it 'converts & to &amp; in translations' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { AndroidWriter.write(languages, terms, tmpdir, :smart, options) }
        content = File.read(File.join(tmpdir, 'values', 'strings.xml'))
        expect(content).to include('&amp; Jerry')
        expect(content).not_to include('"Tom & Jerry"')
      end
    end

    it 'converts ... to … in translations' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { AndroidWriter.write(languages, terms, tmpdir, :smart, options) }
        content = File.read(File.join(tmpdir, 'values', 'strings.xml'))
        expect(content).to include('Wait…')
      end
    end

    it 'converts %@ to %s in translations' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { AndroidWriter.write(languages, terms, tmpdir, :smart, options) }
        content = File.read(File.join(tmpdir, 'values', 'strings.xml'))
        expect(content).to include('%s world')
      end
    end

    it 'renders comment rows as XML comments' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { AndroidWriter.write(languages, terms, tmpdir, :smart, options) }
        content = File.read(File.join(tmpdir, 'values', 'strings.xml'))
        expect(content).to include('<!-- Section General -->')
      end
    end

    it 'includes app_name string resource' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { AndroidWriter.write(languages, terms, tmpdir, :smart, options) }
        content = File.read(File.join(tmpdir, 'values', 'strings.xml'))
        expect(content).to include('<string name="app_name">My App</string>')
      end
    end
  end
end
