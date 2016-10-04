require 'localio/template_handler'
require 'localio/segments_list_holder'
require 'localio/segment'
require 'localio/formatter'

class IosWriter
  def self.write(languages, terms, path, formatter, options)
    puts 'Writing iOS translations...'
    create_constants = options[:create_constants].nil? ? true : options[:create_constants]

    constant_segments = nil
    languages.keys.each do |lang|
      output_path = File.join(path, "#{lang}.lproj/")

      # We have now to iterate all the terms for the current language, extract them, and store them into a new array

      segments = SegmentsListHolder.new lang
      constant_segments = SegmentsListHolder.new lang
      terms.each do |term|
        next if term.values[lang].nil?
        key = Formatter.format(term.keyword, formatter, method(:ios_key_formatter))
        translation = ios_parsing term.values[lang]
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

  def self.ios_parsing(term)
    term.gsub(/<s\$(\d)>/, '%\1$@').#<s$1> -> %1$@ for string/object params
         gsub(/<d\$(\d)>/, '%\1$d').#<d$1> -> %1$d for integer params
         gsub(/<c\$(\d)>/, '%\1$s').#<c$1> -> %1$s for char params
         gsub('"', '\\"')
  end

  private

  def self.ios_key_formatter(key)
    '_'+key.space_to_underscore.strip_tag.capitalize
  end

  def self.ios_constant_formatter(key)
    'kLocale'+key.space_to_underscore.strip_tag.camel_case
  end

end
