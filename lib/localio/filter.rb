class Filter
  def self.apply_filter(segments, only, except)

    segments = only segments, only[:keys] unless only.nil?
    segments = except segments, except[:keys] unless except.nil?

    segments
  end

  private

  def self.only segments, keys_filter

    filtered_segments = []
    segments.each do |segment|
      is_okay = true
      unless keys_filter.nil?
        result = /#{keys_filter}/ =~ segment.keyword
        is_okay = false if result.nil?
      end

      filtered_segments << segment if is_okay
    end

    filtered_segments
  end

  def self.except segments, keys_filter
    filtered_segments = []
    segments.each do |segment|
      is_okay = true
      unless keys_filter.nil?
        result = /#{keys_filter}/ =~ segment.keyword
        is_okay = false unless result.nil?
      end

      filtered_segments << segment if is_okay
    end

    filtered_segments
  end

end