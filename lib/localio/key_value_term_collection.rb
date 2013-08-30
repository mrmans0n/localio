class KeyValueTermCollection

  attr_accessor :items

  def initialize(items)
    @items = items
  end

  def get_binding
    binding()
  end
end