require 'localio/processors/google_drive_processor'
require 'localio/processors/xls_processor'

module Processor
  def self.load_localizables(service, path, options)
    case service
      when :google_drive
        GoogleDriveProcessor.load_localizables(path, options)
      when :xls
        XlsProcessor.load_localizables(path, options)
      else
        abort 'Unsupported service! Try with :google_drive or :xls in the source argument'
    end
  end
end