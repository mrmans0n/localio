require 'csv'
require 'localio/term'

class CsvProcessor

  def self.load_localizables(platform_options, options)

    # Parameter validations
    path = options[:path]
    raise ArgumentError, ':path attribute is missing from the source, and it is required for CSV spreadsheets' if path.nil?

    override_default = nil
    override_default = platform_options[:override_default] unless platform_options.nil? or platform_options[:override_default].nil?

    # , is the default separator; we only set this if we specified a different separator
    separator = options[:column_separator] ||= ','

    csv_file = CSV.read path, col_sep: separator

    # At this point we have the worksheet, so we want to store all the key / values
    first_valid_row_index = nil
    last_valid_row_index = nil

    for row in 1..csv_file.length-1
      first_valid_row_index = row if csv_file[row][0].to_s.downcase == '[key]'
      last_valid_row_index = row if csv_file[row][0].to_s.downcase == '[end]'
    end

    raise IndexError, 'Invalid format: Could not find any [key] keyword in the A column of the CSV file' if first_valid_row_index.nil?
    raise IndexError, 'Invalid format: Could not find any [end] keyword in the A column of the CSV file' if last_valid_row_index.nil?
    raise IndexError, 'Invalid format: [end] must not be before [key] in the A column' if first_valid_row_index > last_valid_row_index

    languages = Hash.new('languages')
    default_language = nil

    for column in 1..csv_file[first_valid_row_index].count-1
      col_all = csv_file[first_valid_row_index][column].to_s
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

    raise 'There are no language columns in the CSV file' if languages.count == 0

    default_language = languages[0] if default_language.to_s == ''
    default_language = override_default unless override_default.nil?

    puts "Languages detected: #{languages.keys.join(', ')} -- using #{default_language} as default."

    puts 'Building terminology in memory...'

    terms = []
    first_term_row = first_valid_row_index+1
    last_term_row = last_valid_row_index-1

    for row in first_term_row..last_term_row
      key = csv_file[row][0]
      unless key.to_s == ''
        term = Term.new(key)
        languages.each do |lang, column_index|
          term_text = csv_file[row][column_index]
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
