class ConfigStore
  CONFIG_FILE = '.localio.yml'

  def initialize
    if File.exist? CONFIG_FILE
      @config = YAML.load_file(CONFIG_FILE)
    end
    @config ||= Hash.new
  end

  def has?(key)
    @config.has_key?(clean_param key)
  end

  def get(key)
    @config[clean_param key]
  end

  def store(key, data)
    @config[clean_param key] = data
  end

  def persist
    File.open(CONFIG_FILE, 'w') do |h|
      h.write @config.to_yaml
    end
  end

  private
  def clean_param(param)
    if param.is_a?(Symbol)
      param.to_s
    else
      param
    end
  end
end
