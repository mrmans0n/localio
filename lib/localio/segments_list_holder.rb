class SegmentsListHolder
  attr_accessor :segments

  def initialize
    @segments = []
  end

  def get_binding
    binding
  end
end