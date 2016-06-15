require 'localio/template_handler'
require 'localio/segments_list_holder'
require 'localio/segment'
require 'localio/formatter'

class IosWriter
  def self.write(languages, terms, path, formatter, options, placeholders)
    puts 'Writing iOS translations...'
    create_constants = options[:create_constants].nil? ? true : options[:create_constants]

    constant_segments = nil
    languages.keys.each do |lang|
      output_path = File.join(path, "#{lang}.lproj/")

      # We have now to iterate all the terms for the current language, extract them, and store them into a new array

      segments = SegmentsListHolder.new lang
      constant_segments = SegmentsListHolder.new lang
      terms.each do |term|
        key = Formatter.format(term.keyword, formatter, method(:ios_key_formatter))
        translation = placeholder_parsing term.values[lang], placeholders
        segment = Segment.new(key, translation, lang)
        segment.key = nil if term.is_comment?
        segments.segments << segment

        unless term.is_comment?
          constant_key = ios_constant_formatter term.keyword
          constant_value = key
          constant_segment = Segment.new(constant_key, constant_value, lang)
          constant_segments.segments << constant_segment
        end
      end

      TemplateHandler.process_template 'ios_localizable.erb', output_path, 'Localizable.strings', segments
      puts " > #{lang.yellow}"
    end

    if create_constants && !constant_segments.nil?
      TemplateHandler.process_template 'ios_constant_localizable.erb', path, 'LocalizableConstants.h', constant_segments
      puts ' > ' + 'LocalizableConstants.h'.yellow
    end

  end

  private

  def self.ios_key_formatter(key)
    '_'+key.space_to_underscore.strip_tag.capitalize
  end

  def self.ios_constant_formatter(key)
    'kLocale'+key.space_to_underscore.strip_tag.camel_case
  end

  def self.placeholder_parsing(term, placeholders)
    if (placeholders.class == NilClass)
        term
    else
        arr = placeholders.values
        re = Regexp.union(arr[0].keys)
        term.gsub(re, arr[0])
    end
  end
end