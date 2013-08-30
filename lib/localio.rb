require 'localio/version'
require 'localio/locfile'
require 'localio/processor'

module Localio

  def self.from_cmdline(args)
    if ARGV.empty?
      if File.exist? 'Locfile'
        process_locfile('Locfile')
      else
        abort 'Locfile not found in current directory'
      end
    else
      process_locfile(ARGV.shift)
    end
  end

  private

  def self.process_locfile(path)
    @locfile = Locfile.load(path)
    generate_localizables
  end

  def self.generate_localizables
    process_to_memory
    build_localizables
  end

  def self.process_to_memory
    @localizables = Processor.load_localizables(@locfile.source_service, @locfile.source_path, @locfile.source_options)
  end

  def self.build_localizables
    case @locfile.platform
      when :android
        puts 'Building for Android!'
      when :ios
        puts 'Building for iOS!'
      when :json
        puts 'Building a JSON!'
      when :yml
        puts 'Building for YAML!'
      when :php
        puts 'Building for PHP!'
      else
        puts 'Madness? This is Sparta!'
    end
  end

end
