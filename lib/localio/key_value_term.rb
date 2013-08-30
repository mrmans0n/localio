class KeyValueTerm
  attr_accessor :formatted_key, :translated_string

  def initialize(key, value)
    @formatted_key = key
    @translated_string = value
  end

end