require 'localio/template_handler'
require 'localio/segments_list_holder'
require 'localio/segment'
require 'localio/formatter'

class OegWriter
  def self.write(languages, terms, path, formatter, options)
    puts 'Writing oeg translations...'

    languages.keys.each do |lang|
      output_path = path
      output_name = "#{lang}.js"

      # We have now to iterate all the terms for the current language, extract them, and store them into a new array

      segments = SegmentsListHolder.new lang
      terms.each do |term|
        next if term.values[lang].nil?
        key = Formatter.format(term.keyword, formatter, method(:oeg_key_formatter))
        translation = oeg_parsing(term.values[lang])
        segment = Segment.new(key, translation, lang)
        segment.key = nil if term.is_comment?
        segments.segments << segment
      end

      # Create a nested hash of the segments (key, translation pairs).
      segments.create_nested_hash

      TemplateHandler.process_template 'oeg_localizable.erb', output_path, output_name, segments
      puts " > #{lang.yellow}"
    end
  end

  def self.oeg_parsing(term)
    term.gsub(/<s\$(\d)>/, '%@\1').#<s$1> -> %@1 for string/object params
         gsub(/<d\$(\d)>/, '%@\1').#<d$1> -> %@1 for integer params
         gsub('""', '\"') #""example"" -> \"example\"
  end

  private

  def self.oeg_key_formatter(key)
    key.space_to_underscore.strip_tag.downcase
  end


end
