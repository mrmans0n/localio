require 'localio/string_helper'
require 'localio/formatter'

RSpec.describe Formatter do
  let(:smart_callback) { ->(key) { key.upcase } }

  describe '.format' do
    it ':smart delegates to callback' do
      expect(Formatter.format('hello', :smart, smart_callback)).to eq('HELLO')
    end

    it ':none returns key unchanged' do
      expect(Formatter.format('Hello World', :none, smart_callback)).to eq('Hello World')
    end

    it ':camel_case converts to CamelCase' do
      expect(Formatter.format('hello world', :camel_case, smart_callback)).to eq('HelloWorld')
    end

    it ':camel_case strips single-letter bracket tags' do
      expect(Formatter.format('[a]hello', :camel_case, smart_callback)).to eq('Hello')
    end

    it ':snake_case converts spaces to underscores and downcases' do
      expect(Formatter.format('Hello World', :snake_case, smart_callback)).to eq('hello_world')
    end

    it 'raises ArgumentError for unknown formatter' do
      expect { Formatter.format('key', :unknown, smart_callback) }.to raise_error(ArgumentError)
    end
  end
end
