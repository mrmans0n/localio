require 'localio/string_helper'

module Formatter
  def self.format(key, formatter, callback)
    case formatter
      when :smart
        # Smart formatting is given by the processor.
        # I don't like this very much but creating more classes seemed overkill.
        callback.call(key)
      when :none
        key
      when :camel_case
        key.space_to_underscore.strip_tag.camel_case
      when :snake_case
        key.space_to_underscore.strip_tag.downcase
      when :strict_snake_case
        key.space_to_underscore.split("_").map { |part| part.strict_underscore }.join("_")
      else
        raise ArgumentError, 'Unknown formatting used. Must use :smart, :none, :camel_case, :snake_case or :strict_snake_case'
    end
  end
end
