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
    nested_hash = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    self.segments.each do |term|
      temp_h = nested_hash
      nested_keys = term.key.split("_")
      nested_keys.each_with_index do |nested_key, index|
        break unless temp_h.is_a? Hash # This skips the translation segment if segment is not nestable
        if index == nested_keys.size - 1
          temp_h[nested_key] = term.translation
        else
          temp_h = temp_h[nested_key]
        end
      end
    end
    @nested_hash = nested_hash
  end
end
