class XlsProcessor

  def self.load_localizables(options)
    path = options[:path]
    abort ':path is missing from the xls source' if path.nil?
    puts "I am the XLS Processor for path #{path}"
  end

end