require 'google_drive'

class GoogleDriveProcessor

  def self.load_localizables(options)
    spreadsheet = options[:spreadsheet]
    abort ':spreadsheet required for Google Drive source!' if spreadsheet.nil?
    login = options[:login]
    abort ':login required for Google Drive source!' if login.nil?
    password = options[:password]
    abort ':password required for Google Drive source!' if password.nil?

    puts 'Logging in to Google Drive...'
    begin
      session = GoogleDrive.login(login, password)
    rescue
      abort 'Couldn\'t access Google Drive. Check your credentials in :login and :password'
    end
    puts 'Logged in!'

    matching_spreadsheets = []
    session.spreadsheets.each do |s|
      matching_spreadsheets << s if s.title.include? spreadsheet
    end

    case matching_spreadsheets.count
      when 1
        puts 'Spreadsheet found. Analyzing...'
      when 0
        abort "Unable to find any spreadsheet matching your criteria: #{spreadsheet}"
      else
        abort 'More than one match found. You have to be more specific!'
    end

  end

end