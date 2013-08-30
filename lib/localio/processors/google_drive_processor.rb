require 'google_drive'
require 'localio/term'

class GoogleDriveProcessor

  def self.load_localizables(options)

    # Parameter validations
    spreadsheet = options[:spreadsheet]
    abort ':spreadsheet required for Google Drive source!' if spreadsheet.nil?
    login = options[:login]
    abort ':login required for Google Drive source!' if login.nil?
    password = options[:password]
    abort ':password required for Google Drive source!' if password.nil?

    # Log in and get spreadsheet
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


    # TODO we could pass a :page_index in the options hash and get that worksheet instead, defaulting to zero?
    worksheet = matching_spreadsheets[0].worksheets[0]
    abort 'Unable to retrieve the first worksheet from the spreadsheet. Are there any pages?' if worksheet.nil?

    # At this point we have the worksheet, so we want to store all the key / values
    first_valid_row_index = nil
    last_valid_row_index = nil

    for row in 1..worksheet.max_rows
      first_valid_row_index = row if worksheet[row, 1].downcase == '[key]'
      last_valid_row_index = row if worksheet[row, 1].downcase == '[end]'
    end

    abort 'Invalid format: Could not find any [key] keyword in the A column of the worksheet' if first_valid_row_index.nil?
    abort 'Invalid format: Could not find any [end] keyword in the A column of the worksheet' if last_valid_row_index.nil?
    abort 'Invalid format: [end] must not be before [key] in the A column' if first_valid_row_index > last_valid_row_index

    languages = Hash.new('languages')
    default_language = nil

    for column in 2..worksheet.max_cols
      col_all = worksheet[first_valid_row_index, column]
      col_all.each_line(' ') do |col_text|
        default_language = col_text.downcase.gsub('*','') if col_text.include? '*'
        languages.store col_text.downcase.gsub('*',''), column unless col_text.to_s == ''
      end
    end

    abort 'There are no language columns in the worksheet' if languages.count == 0

    @default_language = languages[0] if default_language.to_s == ''

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

    # Return the array of terms
    terms
  end

end