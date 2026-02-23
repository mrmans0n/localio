require 'localio/string_helper'
require 'localio/term'
require 'localio/formatter'
require 'localio/writers/twine_writer'

RSpec.describe TwineWriter do
  include_context 'standard terms'
  # standard terms provides: languages {'en'=>1,'es'=>2,'fr'=>3},
  # default_language 'en', and terms:
  #   [comment] "Section General", app_name, greeting, dots_test, ampersand_test

  let(:options) { { default_language: 'en' } }

  describe '.write' do
    it 'creates strings.txt in the output path' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { TwineWriter.write(languages, terms, tmpdir, :smart, options) }
        expect(File).to exist(File.join(tmpdir, 'strings.txt'))
      end
    end

    it 'uses a custom filename when :output_file is specified' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          TwineWriter.write(languages, terms, tmpdir, :smart, options.merge(output_file: 'translations.txt'))
        end
        expect(File).to exist(File.join(tmpdir, 'translations.txt'))
        expect(File).not_to exist(File.join(tmpdir, 'strings.txt'))
      end
    end

    it 'includes all languages for each key' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { TwineWriter.write(languages, terms, tmpdir, :smart, options) }
        content = File.read(File.join(tmpdir, 'strings.txt'))
        expect(content).to include('en = My App')
        expect(content).to include('es = Mi Aplicación')
        expect(content).to include('fr = Mon Application')
      end
    end

    it 'writes [init-node] terms as [[section]] headers' do
      section_terms = [
        Term.new('[init-node]').tap { |t| t.values['en'] = 'General'; t.values['es'] = 'General'; t.values['fr'] = 'General' },
        Term.new('app_name').tap   { |t| t.values['en'] = 'My App';   t.values['es'] = 'Mi App';  t.values['fr'] = 'Mon App' },
        Term.new('[end-node]').tap { |t| t.values['en'] = 'end';      t.values['es'] = 'end';     t.values['fr'] = 'end' },
      ]
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { TwineWriter.write(languages, section_terms, tmpdir, :smart, options) }
        content = File.read(File.join(tmpdir, 'strings.txt'))
        expect(content).to include('[[General]]')
      end
    end

    it 'attaches [comment] value as comment = on the following key' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { TwineWriter.write(languages, terms, tmpdir, :smart, options) }
        content = File.read(File.join(tmpdir, 'strings.txt'))
        # [comment] "Section General" appears before app_name and attaches to it
        expect(content).to include("\t\tcomment = Section General")
        # The comment block appears before the greeting key block
        comment_pos  = content.index('comment = Section General')
        greeting_pos = content.index('[greeting]')
        expect(comment_pos).to be < greeting_pos
      end
    end
  end
end
