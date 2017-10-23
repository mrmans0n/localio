require 'google_drive'
require 'localio/term'
require 'localio/config_store'

class GoogleDriveProcessor

  def self.load_localizables(platform_options, options)
    # Parameter validations
    spreadsheet = options[:spreadsheet]
    raise ArgumentError, ':spreadsheet required for Google Drive source!' if spreadsheet.nil?

    # Deprecate :login & :password
    login = options[:login]
    raise ArgumentError, ':login is deprecated. You should use :client_id and :client_secret for secure OAuth2 authentication.' unless login.nil?
    password = options[:password]
    raise ArgumentError, ':password is deprecated. You should use :client_id and :client_secret for secure OAuth2 authentication.' unless password.nil?

    # New authentication way
    client_id = options[:client_id]
    client_secret = options[:client_secret]

    # We need client_id / client_secret
    raise ArgumentError, ':client_id required for Google Drive. Check how to get it here: https://developers.google.com/drive/web/auth/web-server' if client_id.nil?
    raise ArgumentError, ':client_secret required for Google Drive. Check how to get it here: https://developers.google.com/drive/web/auth/web-server' if client_secret.nil?

    override_default = nil
    override_default = platform_options[:override_default] unless platform_options.nil? or platform_options[:override_default].nil?

    # Log in and get spreadsheet
    puts 'Logging in to Google Drive...'
    begin
      client = Google::APIClient.new application_name: 'Localio', application_version: Localio::VERSION
      auth = client.authorization
      auth.client_id = client_id
      auth.client_secret = client_secret
      auth.scope =
          "https://docs.google.com/feeds/" +
              "https://www.googleapis.com/auth/drive " +
              "https://spreadsheets.google.com/feeds/"
      auth.redirect_uri = "urn:ietf:wg:oauth:2.0:oob"

      config = ConfigStore.new

      access_token = nil

      if options.has_key?(:client_token)
        puts 'Refreshing auth token...'
        auth.refresh_token = options[:client_token]
        auth.refresh!
        access_token = auth.access_token
      elsif config.has? :refresh_token
        puts 'Refreshing auth token...'
        auth.refresh_token = config.get :refresh_token
        auth.refresh!
        access_token = auth.access_token
      else
        puts "1. Open this page in your browser:\n#{auth.authorization_uri}\n\n"
        puts "2. Enter the authorization code shown in the page: "
        auth.code = $stdin.gets.chomp
        auth.fetch_access_token!
        access_token = auth.access_token
      end

    if !options.has_key?(:client_token)
      puts 'Store auth data...'
      config.store :refresh_token, auth.refresh_token
      config.store :access_token, auth.access_token
      config.persist
    end

      # Creates a session
      session = GoogleDrive.login_with_oauth(access_token)
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


    # TODO we could pass a :page_index in the options hash and get that worksheet instead, defaulting to zero?
    worksheet = matching_spreadsheets[0].worksheets[0]
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
