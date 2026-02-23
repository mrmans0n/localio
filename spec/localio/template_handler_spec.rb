require 'localio/string_helper'
require 'localio/segment'
require 'localio/segments_list_holder'
require 'localio/template_handler'

RSpec.describe TemplateHandler do
  let(:holder) do
    h = SegmentsListHolder.new('en')
    h.segments << Segment.new('app_name', 'My App', 'en')
    h.segments << Segment.new('greeting', 'Hello world', 'en')
    h
  end

  describe '.process_template' do
    it 'creates the output file in the target directory' do
      Dir.mktmpdir do |tmpdir|
        workdir = File.join(tmpdir, 'work')
        FileUtils.mkdir_p(workdir)
        target  = File.join(tmpdir, 'out')
        Dir.chdir(workdir) do
          TemplateHandler.process_template('rails_localizable.erb', target, 'en.yml', holder)
          expect(File).to exist(File.join(target, 'en.yml'))
        end
      end
    end

    it 'renders ERB template content correctly' do
      Dir.mktmpdir do |tmpdir|
        workdir = File.join(tmpdir, 'work')
        FileUtils.mkdir_p(workdir)
        target  = File.join(tmpdir, 'out')
        Dir.chdir(workdir) do
          TemplateHandler.process_template('rails_localizable.erb', target, 'en.yml', holder)
          content = File.read(File.join(target, 'en.yml'))
          expect(content).to include('en:')
          expect(content).to include('app_name: "My App"')
          expect(content).to include('greeting: "Hello world"')
        end
      end
    end

    it 'does not leave a stray temp file in the working directory' do
      Dir.mktmpdir do |tmpdir|
        workdir = File.join(tmpdir, 'work')
        FileUtils.mkdir_p(workdir)
        target  = File.join(tmpdir, 'out')
        Dir.chdir(workdir) do
          TemplateHandler.process_template('rails_localizable.erb', target, 'en.yml', holder)
          files = Dir.entries(workdir).reject { |f| f.start_with?('.') }
          expect(files).to be_empty
        end
      end
    end

    it 'creates subdirectories as needed' do
      Dir.mktmpdir do |tmpdir|
        workdir = File.join(tmpdir, 'work')
        FileUtils.mkdir_p(workdir)
        Dir.chdir(workdir) do
          subdir = File.join(tmpdir, 'out', 'values')
          TemplateHandler.process_template('rails_localizable.erb', subdir, 'en.yml', holder)
          expect(File).to exist(File.join(subdir, 'en.yml'))
        end
      end
    end
  end
end
