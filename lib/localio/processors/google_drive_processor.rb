require 'google_drive'
require 'localio/term'

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

    # We need client_id / client_secret (unless a service-account key is supplied)
    unless options[:client_token].is_a?(String) && File.file?(options[:client_token].to_s)
      raise ArgumentError, ':client_id required for Google Drive. Check how to get it here: https://developers.google.com/drive/web/auth/web-server' if client_id.nil?
      raise ArgumentError, ':client_secret required for Google Drive. Check how to get it here: https://developers.google.com/drive/web/auth/web-server' if client_secret.nil?
    end

    override_default = nil
    override_default = platform_options[:override_default] unless platform_options.nil? or platform_options[:override_default].nil?

    # Log in and get spreadsheet
    puts 'Logging in to Google Drive...'
    begin
      session = nil

      # Service-account key file (JSON) path supplied via :client_token
      if options[:client_token].is_a?(String) && File.file?(options[:client_token].to_s)
        session = GoogleDrive::Session.from_service_account_key(options[:client_token])
      else
        # OAuth2 config-file flow (from_config saves/loads the refresh token)
        config_path = File.join(Dir.home, '.localio_gdrive_config.json')
        session = GoogleDrive::Session.from_config(
          config_path,
          client_id: client_id,
          client_secret: client_secret
        )
      end
    rescue => e
      puts "Error: #{e.inspect}"
      raise 'Couldn\'t access Google Drive. Check your values for :client_id and :client_secret.'
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

    sheet = options[:sheet]
    worksheet = if sheet.is_a? Integer
                  matching_spreadsheets[0].worksheets[sheet]
                elsif sheet.is_a? String
                  matching_spreadsheets[0].worksheets.detect { |s| s.title == sheet }
                end


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
        default_language = col_text.gsub('*', '') if col_text.include? '*'
        lang = col_text.gsub('*', '')

        unless platform_options[:avoid_lang_downcase]
          default_language = default_language.downcase
          lang = lang.downcase
        end

        unless col_text.to_s == ''
          languages.store lang, column
        end
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
