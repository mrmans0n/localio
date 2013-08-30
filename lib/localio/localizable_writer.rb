require 'localio/writers/android_writer'
require 'localio/writers/ios_writer'

module LocalizableWriter
  def self.write(platform, terms, formatter)
    case platform
      when :android
        AndroidWriter.write terms, formatter
      when :ios
        IosWriter.write terms, formatter
      when :json
        raise 'Not implemented yet'
      when :yml
        raise 'Not implemented yet'
      when :php
        raise 'Not implemented yet'
      else
        abort 'Platform not supported! Current possibilities are :android, :ios, :json, :yml, :php'
    end
  end
end