require 'localio/module'

class Locfile

  # Specify the target platform for the localizables
  #
  # possible values
  # :android, :ios, :rails, :json
  dsl_accessor :platform_name, :platform_options

  # Specifies the filesystem path where the generated files will be
  dsl_accessor :output_path

  # Specifies the file name of the generated files
  dsl_accessor :output_filename
  
  # Specifies the format for the keys in the localizable file
  #
  # :smart - choose the formatting depending on the platform's best practices. This is the best option for multiplatform apps.
  # :camel_case - camel case formatting (ie thisKindOfKeys)
  # :snake_case - snake case formatting (ie this_kind_of_keys)
  # :none - no formatting done, the keys will be used as
  dsl_accessor :formatting

  # Specify a filter that we can use for keys. It would work as "put everything except what matches with this key"
  dsl_accessor :except

  # Specify a filter that we can use for keys. It would work as "put only what matches with this key"
  dsl_accessor :only

  # Defined using 'source' ideally
  dsl_accessor :source_service, :source_options

  def initialize
    @platform_name = nil
    @platform_options = nil
    @source_service = :google_drive
    @source_path = nil
    @source_options = nil
    @output_path = './out/'
    @output_filename = nil
    @formatting = :smart
  end

  # Defines the platform
  #
  # service : any of the supported ones (see above)
  # options : hash with extra options, view documentation for the different services
  def platform(name, options = {})
    @platform_name = name
    @platform_options = options
  end

  # Defines the service storing the translations
  #
  # service : can be :google_drive, :xls
  # options : hash with extra options, view documentation for the different services
  def source(service, options = {})
    @source_service = service
    @source_options = options
  end

  def self.load(filename)
    dsl = new
    dsl.instance_eval(File.read(filename), filename)
    dsl
  end

end