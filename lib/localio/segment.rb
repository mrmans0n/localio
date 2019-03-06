class Segment

  attr_accessor :key, :translation, :language, :nested

  def initialize(key, translation, language)
    @key = key
    @translation = translation.to_s.replace_escaped
    @language = language
    @nested = []
  end

  def is_comment?
    @key == nil
  end

  def with_nesting?
    !@nested.empty?
  end
end
