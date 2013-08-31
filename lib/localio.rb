require 'localio/version'
require 'localio/locfile'
require 'localio/processor'
require 'localio/localizable_writer'

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

  def self.from_configuration(configuration)
    @configuration = configuration
    generate_localizables
  end

  private

  def self.process_locfile(path)
    @configuration = Locfile.load(path)
    generate_localizables
  end

  def self.generate_localizables
    process_to_memory
    build_localizables
  end

  def self.process_to_memory
    @localizables = Processor.load_localizables @configuration.source_service,
                                                @configuration.source_options
  end

  def self.build_localizables
    LocalizableWriter.write @configuration.platform,
                            @localizables[:languages],
                            @localizables[:segments],
                            @configuration.output_path,
                            @configuration.formatting,
                            :default_language => @localizables[:default_language]
    puts 'Done!'
  end

end
