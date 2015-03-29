require 'localio/processors/google_drive_processor'
require 'localio/processors/xls_processor'
require 'localio/processors/xlsx_processor'
require 'localio/processors/csv_processor'

module Processor
  def self.load_localizables(platform_options, service, options)
    case service
      when :google_drive
        GoogleDriveProcessor.load_localizables platform_options, options
      when :xls
        XlsProcessor.load_localizables platform_options, options
      when :xlsx
        XlsxProcessor.load_localizables platform_options, options
      when :csv
        CsvProcessor.load_localizables platform_options, options
      else
        raise ArgumentError, 'Unsupported service! Try with :google_drive, :csv, :xlsx or :xls in the source argument'
    end
  end
end