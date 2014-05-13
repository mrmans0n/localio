require 'simple_xlsx_reader'
require 'localio/term'

class XlsxProcessor

  def self.load_localizables(platform_options, options)

    # Parameter validations
    path = options[:path]
    raise ArgumentError, ':path attribute is missing from the source, and it is required for xlsx spreadsheets' if path.nil?

    override_default = nil
    override_default = platform_options[:override_default] unless platform_options.nil? or platform_options[:override_default].nil?

    book = SimpleXlsxReader.open path

    # TODO we could pass a :page_index in the options hash and get that worksheet instead, defaulting to zero?
    worksheet = book.sheets.first
    raise 'Unable to retrieve the first worksheet from the spreadsheet. Are there any pages?' if worksheet.nil?

    # At this point we have the worksheet, so we want to store all the key / values
    first_valid_row_index = nil
    last_valid_row_index = nil
        
    for row in 1..worksheet.rows.count-1
      first_valid_row_index = row if worksheet.rows[row][0].to_s.downcase == '[key]'
      last_valid_row_index = row if worksheet.rows[row][0].to_s.downcase == '[end]'
    end
    
    raise IndexError, 'Invalid format: Could not find any [key] keyword in the A column of the worksheet' if first_valid_row_index.nil?
    raise IndexError, 'Invalid format: Could not find any [end] keyword in the A column of the worksheet' if last_valid_row_index.nil?
    raise IndexError, 'Invalid format: [end] must not be before [key] in the A column' if first_valid_row_index > last_valid_row_index

    languages = Hash.new('languages')
    default_language = nil
    
    for column in 1..worksheet.rows[first_valid_row_index].count-1
      col_all = worksheet.rows[first_valid_row_index][column].to_s
      col_all.each_line(' ') do |col_text|
        default_language = col_text.downcase.gsub('*','') if col_text.include? '*'
        languages.store col_text.downcase.gsub('*',''), column unless col_text.to_s == ''
      end
    end
    
    raise 'There are no language columns in the worksheet' if languages.count == 0

    default_language = languages[0] if default_language.to_s == ''
    default_language = override_default unless override_default.nil?

    puts "Languages detected: #{languages.keys.join(', ')} -- using #{default_language} as default."

    puts 'Building terminology in memory...'

    terms = []
    first_term_row = first_valid_row_index+1
    last_term_row = last_valid_row_index-1

    for row in first_term_row..last_term_row
      key = worksheet.rows[row][0]
      unless key.to_s == ''
        term = Term.new(key)
        languages.each do |lang, column_index|
          term_text = worksheet.rows[row][column_index]
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