require 'localio/processors/google_drive_processor'
require 'localio/processors/xls_processor'
# require 'localio/processors/xlsx_processor'

module Processor
  def self.load_localizables(service, options)
    case service
      when :google_drive
        GoogleDriveProcessor.load_localizables options
      when :xls
        XlsProcessor.load_localizables options
      when :xlsx
        raise 'Temporarily disabled due to rubyzip problems. Sorry!'
        # XlsxProcessor.load_localizables options
      else
        raise ArgumentError, 'Unsupported service! Try with :google_drive, :xlsx or :xls in the source argument'
    end
  end
end