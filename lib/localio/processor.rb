module Processor
  def self.new(service, path, options)
    case service
      when :google_drive
        GoogleDriveProcessor.new(path, options)
      else
        raise 'Unsupported service!'
    end
  end
end