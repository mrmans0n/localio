class SegmentsListHolder
  attr_accessor :segments, :language

  def initialize(language)
    @segments = []
    @language = language
  end

  def get_binding
    binding
  end
end