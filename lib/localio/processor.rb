require 'localio/processors/google_drive_processor'

module Processor
  def self.new(service, path, options)
    case service
      when :google_drive
        GoogleDriveProcessor.new(path, options)
      when :xls
        raise 'Not implemented (but planned!)'
      else
        raise 'Unsupported service!'
    end
  end
end