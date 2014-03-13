require 'localio/template_handler'
require 'localio/segments_list_holder'
require 'localio/segment'
require 'localio/formatter'

class JavaPropertiesWriter
  def self.write(languages, terms, path, formatter, options)
    puts 'Writing Java Properties translations...'

    languages.keys.each do |lang|
      output_path = path

      # We have now to iterate all the terms for the current language, extract them, and store them into a new array

      segments = SegmentsListHolder.new lang
      terms.each do |term|
        key = Formatter.format(term.keyword, formatter, method(:java_properties_key_formatter))
        translation = term.values[lang]
        segment = Segment.new(key, translation, lang)
        segment.key = nil if term.is_comment?
        segments.segments << segment
      end
      TemplateHandler.process_template 'java_properties_localizable.erb', output_path, "language_#{lang}.properties", segments
      puts " > #{lang.yellow}"
    end
  end

  private

  def self.java_properties_key_formatter(key)
    key.space_to_underscore.strip_tag.downcase
  end
end