require 'localio/string_helper'

module Formatter
  def self.format(key, formatter, &block)
    case formatter
      when :smart
        # Smart formatting is given by the processor.
        # I don't like this very much but creating more classes seemed overkill.
        callback = block
        callback.call(key)
      when :none
        key
      when :camel_case
        key.camel_case
      when :snake_case
        key.space_to_underscore.strip_tag.downcase
      else
        abort 'Unknown formatting used. Must use :smart, :none, :camel_case or :snake_case'
    end
  end
end