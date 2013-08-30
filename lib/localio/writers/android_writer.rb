require 'localio/template_handler'
require 'localio/key_value_term_collection'
require 'localio/formatter'

class AndroidWriter
  def self.write(languages, terms, path, formatter, options)
    puts "Write to Android #{terms.count.to_s} terms with formatter #{formatter}"
    default_language = options[:default_language]

    languages.keys.each do |lang|
      output_path = path + "values-#{lang}/"
      output_path = path + 'values/' if default_language == lang

      # We have now to iterate all the terms for the current language and store them into a new array


      # TemplateHandler.process_template 'android_localizable.erb', output_path, 'strings.xml'
    end

  end

  private

  def self.get_values(term)

  end
end