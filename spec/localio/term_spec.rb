require 'localio/term'

RSpec.describe Term do
  subject(:term) { Term.new('app_name') }

  it 'stores the keyword' do
    expect(term.keyword).to eq('app_name')
  end

  it 'initializes with empty values hash' do
    expect(term.values).to be_empty
  end

  it 'stores values by language' do
    term.values['en'] = 'My App'
    expect(term.values['en']).to eq('My App')
  end

  describe '#is_comment?' do
    it { expect(Term.new('[comment]').is_comment?).to be true }
    it { expect(Term.new('[COMMENT]').is_comment?).to be true }
    it { expect(term.is_comment?).to be false }
  end
end
