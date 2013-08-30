class Locfile

  attr_reader :platform, :source_service, :source_path, :source_options, :output_path, :formatting

  def initialize
    @platform = nil
    @source_service = :google_drive
    @source_path = nil
    @source_options = nil
    @output_path = './out/'
    @formatting = :smart
  end

  # Specify the target platform for the localizables
  #
  # possible values
  # :android, :ios, :php, :json, :yml
  def platform(platform)
    @platform = platform
    puts "Setting platform #{platform}"
  end

  # Defines the service storing the translations
  #
  # service
  #   :google_drive
  #
  # path : URL or system path storing the data
  # options : hash with extra options, view documentation for the different services
  def source(service, path, options = {})
    @source_service = service
    @source_path = path
    @source_options = options
    puts "Setting source service #{service} and source path #{path} with options #{options}"
  end

  # Specifies the filesystem path where the generated files will be
  def output_path(path)
    @output_path = path
    puts "Setting output path #{path}"
  end

  # Specifies the format for the keys in the localizable file
  #
  # smart : choose the formatting depending on the platform's best practices. This is the best option for multiplatform apps.
  # camel_case : camel case formatting (ie thisKindOfKeys)
  # snake_case : snake case formatting (ie this_kind_of_keys)
  # none : no formatting done, the keys will be used as
  def formatting(formatting)
    @formatting = formatting
    puts "Setting formatting to #{formatting}"
  end

  def self.load(filename)
    new.instance_eval(File.read(filename), filename)
    generate_localizables
  end

  private


  def self.generate_localizables
    process_to_memory
    build_localizables
  end

  def self.process_to_memory
    Processor.new(@source_service, @source_path, @source_options)
  end

  def self.build_localizables
    case @platform
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