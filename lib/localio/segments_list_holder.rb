class SegmentsListHolder
  attr_accessor :segments, :language, :nested_hash

  def initialize(language)
    @segments = []
    @nested_hash = {}
    @language = language
  end

  def get_binding
    binding
  end

  def create_nested_hash
    h = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    self.segments.each do |term|
      temp_h = h
      nested_keys = term.key.split("_")
      nested_keys.each_with_index do |nested_key, index|
        if index == nested_keys.size - 1
          next if temp_h[nested_key].nil? # This ignores the translation segment if the segment is not nestable
          temp_h[nested_key] = term.translation
        else
          temp_h = temp_h[nested_key]
        end
      end
    end
    self.nested_hash = h
  end
end
