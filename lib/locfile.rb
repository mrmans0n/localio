require 'docile'

class Locfile
  # To change this template use File | Settings | File Templates.

  def initialize
    @source_service = :google_drive
    @formatting = :smart
    @path = './out/'
  end

  def platform(platform)
    @platform = platform
    puts "Setting platform #{platform}"
  end

  def source(source_service, source_path)
    @source_service = source_service
    @source_path = source_path
    puts "Setting source service #{source_service} and source path #{source_path}"
  end

  # Specifies the filesystem path where the generated files will be
  def path(path)
    @path = path
    puts "Setting path #{path}"
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
  end
  
end