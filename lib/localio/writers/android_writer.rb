require 'localio/template_handler'
require 'localio/segments_list_holder'
require 'localio/segment'
require 'localio/formatter'
require 'nokogiri'

class AndroidWriter
  def self.write(languages, terms, path, formatter, options, placeholders)
    puts 'Writing Android translations...'
    default_language = options[:default_language]

    languages.keys.each do |lang|
      output_path = File.join(path,"values-#{lang}/")
      output_path = File.join(path,'values/') if default_language == lang

      # We have now to iterate all the terms for the current language, extract them, and store them into a new array

      segments = SegmentsListHolder.new lang
      terms.each do |term|
        key = Formatter.format(term.keyword, formatter, method(:android_key_formatter))
        translation = placeholder_parsing term.values[lang], placeholders
        segment = Segment.new(key, translation, lang)
        segment.key = nil if term.is_comment?
        segments.segments << segment
      end

      TemplateHandler.process_template 'android_localizable.erb', output_path, 'strings.xml', segments
      puts " > #{lang.yellow}"
    end

  end

  private

  def self.android_key_formatter(key)
    key.space_to_underscore.strip_tag.downcase
  end

  def self.placeholder_parsing(term, placeholders)
    if (placeholders.class == NilClass)
        term.gsub('& ','&amp; ').gsub('...', '…')
    else
        arr = placeholders.values
        re = Regexp.union(arr[0].keys)
        term.gsub('& ','&amp; ').gsub('...', '…').gsub(re, arr[0])
    end
  end
end