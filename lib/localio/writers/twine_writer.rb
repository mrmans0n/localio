require 'fileutils'
require 'localio/formatter'

class TwineWriter
  def self.write(languages, terms, path, formatter, options)
    puts 'Writing Twine translations...'

    default_language = options[:default_language]
    output_filename  = options[:output_file] || 'strings.txt'

    FileUtils.mkdir_p(path)

    File.open(File.join(path, output_filename), 'w') do |f|
      pending_comment = nil

      terms.each do |term|
        if term.is_comment?
          pending_comment = term.values[default_language]
        elsif term.keyword == '[init-node]'
          f.puts "[[#{term.values[default_language]}]]"
          pending_comment = nil
        elsif term.keyword == '[end-node]'
          f.puts ''
          pending_comment = nil
        else
          key = Formatter.format(term.keyword, formatter, method(:twine_key_formatter))
          f.puts "\t[#{key}]"
          languages.keys.each do |lang|
            f.puts "\t\t#{lang} = #{term.values[lang]}"
          end
          if pending_comment
            f.puts "\t\tcomment = #{pending_comment}"
            pending_comment = nil
          end
          f.puts ''
        end
      end
    end

    puts " > #{output_filename.yellow}"
  end

  private

  def self.twine_key_formatter(key)
    key.space_to_underscore.strip_tag.downcase
  end
end
