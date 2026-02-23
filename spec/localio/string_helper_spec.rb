require 'localio/string_helper'

RSpec.describe String do
  describe '#space_to_underscore' do
    it { expect('hello world'.space_to_underscore).to eq('hello_world') }
    it { expect('hello'.space_to_underscore).to eq('hello') }
  end

  describe '#strip_tag' do
    it 'strips single-letter bracket tags from the start' do
      expect('[a]hello'.strip_tag).to eq('hello')
    end
    it 'does not strip multi-letter bracket tags' do
      expect('[comment]hello'.strip_tag).to eq('[comment]hello')
    end
    it 'does not strip tags not at the start' do
      expect('hello[a]'.strip_tag).to eq('hello[a]')
    end
  end

  describe '#camel_case' do
    it { expect('hello_world'.camel_case).to eq('HelloWorld') }
    it { expect('HelloWorld'.camel_case).to eq('HelloWorld') }
  end

  describe '#replace_escaped' do
    it { expect('a`+b'.replace_escaped).to eq('a+b') }
    it { expect('a`=b'.replace_escaped).to eq('a=b') }
    it { expect("a\\+b".replace_escaped).to eq('a+b') }
  end

  describe '#underscore' do
    it { expect('HelloWorld'.underscore).to eq('hello_world') }
  end

  describe '#uncapitalize' do
    it { expect('Hello'.uncapitalize).to eq('hello') }
  end

  describe '#blank?' do
    it { expect(''.blank?).to be true }
    it { expect('hello'.blank?).to be false }
  end

  describe '#green / #yellow / #red / #cyan' do
    it { expect('ok'.green).to include("\e[32m") }
    it { expect('ok'.yellow).to include("\e[33m") }
  end
end
