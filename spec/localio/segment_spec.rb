require 'localio/string_helper'
require 'localio/segment'

RSpec.describe Segment do
  subject(:segment) { Segment.new('app_name', 'My App', 'en') }

  it 'stores key, translation, and language' do
    expect(segment.key).to eq('app_name')
    expect(segment.translation).to eq('My App')
    expect(segment.language).to eq('en')
  end

  it 'processes translation through replace_escaped' do
    seg = Segment.new('key', 'hello`+world', 'en')
    expect(seg.translation).to eq('hello+world')
  end

  describe '#is_comment?' do
    it 'returns true when key is nil' do
      segment.key = nil
      expect(segment.is_comment?).to be true
    end
    it 'returns false when key is set' do
      expect(segment.is_comment?).to be false
    end
  end
end
