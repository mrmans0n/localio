require 'pry'
require 'localio/template_handler'
require 'localio/segments_list_holder'
require 'localio/segment'
require 'localio/formatter'

class RailsNestedWriter
  DEFAULT_SEPARATOR = ' '.freeze

  def self.write(languages, terms, path, formatter, options)
    puts 'Writing Rails YAML translations...'

    @nesting_separator = options[:separator] || DEFAULT_SEPARATOR
    @key_formatter = formatter

    languages.keys.each do |lang|
      @lang = lang
      segments_holder = SegmentsListHolder.new(lang)

      @segments = segments_holder.segments
      prepare_segments!(terms)

      TemplateHandler.process_template 'rails_localizable.erb', path, "#{lang}.yml", segments_holder
      puts " > #{lang.yellow}"
    end
  end

  private

  def self.rails_key_formatter(key)
    key.space_to_underscore.strip_tag.downcase
  end

  def self.prepare_segments!(terms, deep=0, root=nil)
    gterms = terms.group_by{ |t| split_key(t.keyword)[0..deep] }
    segment_list = root.nil? ? @segments : root.nested

    gterms.each do |_keys, _terms|
      if _terms.size == 1 && _keys.size == split_key(_terms[0].keyword).size
        key = _terms[0].is_comment? ? nil : split_key(_terms[0].keyword).last
        add_segment(key, _terms[0].values[@lang], segment_list)
      else
        key = _keys[0..deep].last
        segment = add_segment(key, nil, segment_list)
        prepare_segments!(_terms, deep + 1, segment)
      end
    end
  end

  def self.split_key(key)
    key.split(@nesting_separator)
  end

  def self.add_segment(key, translation, segments)
    k = Formatter.format(key, @key_formatter, method(:rails_key_formatter))
    segment = Segment.new(k, translation, @lang)
    segments << segment
    segment
  end
end
