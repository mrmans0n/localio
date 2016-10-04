class SegmentsListHolder
  attr_accessor :segments, :language

  def initialize(language)
    @segments = []
    @nested_hash = {}
    @language = language
  end

  def get_binding
    binding
  end

  def create_nested_hash
    result_hash = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    segments.each do |segment|
      pointer = result_hash
      keys = segment.key.split("_")
      keys.each_with_index do |key, index|
        break unless pointer.is_a? Hash # This skips the translation segment if segment is not nestable
        if index == keys.size - 1
          pointer[key] = segment.translation
        else
          pointer = pointer[key]
        end
      end
    end
    @nested_hash = result_hash
  end

end
