class GoogleDriveProcessor

  def self.load_localizables(path, options)
    login = options[:login]
    abort ':login required for Google Drive source!' if login.nil?
    password = options[:password]
    abort ':password required for Google Drive source!' if password.nil?
    puts "I am the Google Drive Processor for path #{path} and for login #{login} / #{password}. Behold!"
  end

end