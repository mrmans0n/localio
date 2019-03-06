class Term
  COMMENT_MATCHER = /^\[comment\]\d*/
  attr_accessor :values, :keyword

  def initialize(keyword)
    @keyword = keyword
    @values = Hash.new
  end

  def is_comment?
    @keyword.downcase.match(COMMENT_MATCHER)
  end
end
