require 'localio/version'
require 'localio/locfile'
require 'localio/processor'

module Localio

  def self.from_cmdline(args)
    if ARGV.empty?
      if File.exist? 'Locfile'
        load_locfile('Locfile')
      else
        raise 'Locfile not found in current directory'
      end
    else
      load_locfile(ARGV.shift)
    end
  end

  private

  def self.load_locfile(path)
    Locfile.load(path)
  end

end
