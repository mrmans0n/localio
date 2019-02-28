class Segment

  attr_accessor :key, :translation, :language

  def initialize(key, translation, language)
    @key = key
    @translation = translation.to_s.replace_escaped
    @language = language
  end

  def is_comment?
    @key == nil
  end
end
