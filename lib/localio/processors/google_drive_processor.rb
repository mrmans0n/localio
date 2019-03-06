require 'google_drive'
require 'localio/term'
require 'localio/config_store'

class GoogleDriveProcessor

  def self.load_localizables(platform_options, options)
    # Parameter validations
    spreadsheet = options[:spreadsheet]
    sheet = options[:sheet]
    raise ArgumentError, ':spreadsheet required for Google Drive source!' if spreadsheet.nil?

    # Deprecate :login & :password
    unless options.slice(:login, :password).empty?
      raise ArgumentError, 'login and password are deprecated. Use client_id and client_secret options'
    end

    # New authentication way
    client_id = options[:client_id]
    client_secret = options[:client_secret]

    # We need client_id / client_secret
    if [client_id, client_secret].any?(&:nil?)
      raise ArgumentError, """
        client_id and client_secret required for Google Drive.
        Check how to get it here: https://developers.google.com/drive/web/auth/web-server
      """
    end

    override_default = platform_options[:override_default] unless platform_options.nil? || platform_options[:override_default].nil?

    # Log in and get spreadsheet
    puts 'Logging in to Google Drive...'
    begin
      credentials = Google::Auth::UserRefreshCredentials.new(
        client_id: client_id,
        client_secret: client_secret,
        scope: ["https://www.googleapis.com/auth/drive", "https://spreadsheets.google.com/feeds/"],
        redirect_uri: "urn:ietf:wg:oauth:2.0:oob",
        additional_parameters: { "access_type" => "offline" }
      )

      cred_storage = ConfigStore.new

      if cred_storage.has?(:refresh_token)
        puts 'Refreshing auth token...'
        credentials.refresh_token = cred_storage.get(:refresh_token)
        credentials.fetch_access_token!
        # access_token = credentials.access_token
      else
        puts "1. Open this page in your browser:\n#{credentials.authorization_uri}\n\n"
        puts "2. Enter the authorization code shown in the page: "
        credentials.code = $stdin.gets.chomp
        credentials.fetch_access_token!
        # access_token = credentials.access_token
      end

      puts 'Store auth data for the future usage...'
      cred_storage.store :refresh_token, credentials.refresh_token
      cred_storage.store :access_token, credentials.access_token
      cred_storage.persist

      # Creates a session
      session = GoogleDrive::Session.from_credentials(credentials)
    rescue => e
      puts "Error: #{e.inspect}"
      raise 'Couldn\'t access Google Drive. Check your values for :client_id and :client_secret, and delete :access_token if present (you might need to refresh its value so please remove it)'
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
        abort "More than one match found (#{matching_spreadsheets.join ', '}). You have to be more specific!"
    end

    worksheets = matching_spreadsheets[0].worksheets
    worksheet  = !sheet.nil? ? (sheet.is_a?(Integer) ? worksheets[sheet] : worksheets.find{ |w| w.title == sheet }) : worksheets[0]
    raise 'Unable to retrieve the first worksheet from the spreadsheet. Are there any pages?' if worksheet.nil?

    # At this point we have the worksheet, so we want to store all the key / values
    first_valid_row_index = nil
    last_valid_row_index = nil

    for row in 1..worksheet.max_rows
      first_valid_row_index = row if worksheet[row, 1].downcase == '[key]'
      last_valid_row_index = row if worksheet[row, 1].downcase == '[end]'
    end

    raise IndexError, 'Invalid format: Could not find any [key] keyword in the A column of the worksheet' if first_valid_row_index.nil?
    raise IndexError, 'Invalid format: Could not find any [end] keyword in the A column of the worksheet' if last_valid_row_index.nil?
    raise IndexError, 'Invalid format: [end] must not be before [key] in the A column' if first_valid_row_index > last_valid_row_index

    languages = Hash.new('languages')
    default_language = nil

    for column in 2..worksheet.max_cols
      col_all = worksheet[first_valid_row_index, column]
      col_all.each_line(' ') do |col_text|
        default_language = col_text.downcase.gsub('*', '') if col_text.include? '*'
        languages.store col_text.downcase.gsub('*', ''), column unless col_text.to_s == ''
      end
    end

    abort 'There are no language columns in the worksheet' if languages.count == 0

    default_language = languages[0] if default_language.to_s == ''
    default_language = override_default unless override_default.nil?

    puts "Languages detected: #{languages.keys.join(', ')} -- using #{default_language} as default."

    puts 'Building terminology in memory...'

    terms = []
    first_term_row = first_valid_row_index+1
    last_term_row = last_valid_row_index-1

    for row in first_term_row..last_term_row
      key = worksheet[row, 1]
      unless key.to_s == ''
        term = Term.new(key)
        languages.each do |lang, column_index|
          term_text = worksheet[row, column_index]
          term.values.store lang, term_text
        end
        terms << term
      end
    end

    puts 'Loaded!'

    # Return the array of terms, languages and default language
    res = Hash.new
    res[:segments] = terms
    res[:languages] = languages
    res[:default_language] = default_language

    res
  end

end
