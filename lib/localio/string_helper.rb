class String
  def self.colorize(text, color_code)
    "\e[#{color_code}m#{text}\e[0m"
  end

  def cyan
    self.class.colorize(self, 36)
  end

  def green
    self.class.colorize(self, 32)
  end

  def yellow
    self.class.colorize(self, 33)
  end

  def red
    self.class.colorize(self, 31)
  end

  def underscore
    self.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
        gsub(/([a-z\d])([A-Z])/, '\1_\2').
        tr("-", "_").
        downcase
  end

  def strip_tag
    self.gsub(/^[\[][a-z][\]]/, '')
  end

  def space_to_underscore
    self.gsub(' ', '_')
  end

  def camel_case
    return self if self !~ /_/ && self =~ /[A-Z]+.*/
    split('_').map{|e| e.capitalize}.join
  end

  def uncapitalize
    self[0, 1].downcase + self[1..-1]
  end

  def blank?
    respond_to?(:empty?) ? empty? : !self
  end
end