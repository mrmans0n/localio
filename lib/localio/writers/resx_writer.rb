require 'localio/template_handler'
require 'localio/segments_list_holder'
require 'localio/segment'
require 'localio/formatter'

class ResXWriter
  def self.write(languages, terms, path, formatter, options)
    puts 'Writing .NET ResX translations...'
    default_language = options[:default_language]
    resource_file = options[:resource_file].nil? ? "Resources" : options[:resource_file]

    languages.keys.each do |lang|
      file_name = "#{resource_file}.#{lang}.resx"
      file_name = "#{resource_file}.resx" if default_language == lang

      # We have now to iterate all the terms for the current language, extract them, and store them into a new array

      segments = SegmentsListHolder.new lang
      terms.each do |term|
        key = Formatter.format(term.keyword, formatter, method(:resx_key_formatter))
        translation = term.values[lang]
        segment = Segment.new(key, translation, lang)
        segment.key = nil if term.is_comment?
        segments.segments << segment
      end

      TemplateHandler.process_template 'resx_localizable.erb', path, file_name, segments
      puts " > #{lang.yellow}"
    end

  end

  private

  def self.resx_key_formatter(key)
    key.space_to_underscore.strip_tag.camel_case.gsub("_", "").capitalize
  end
end