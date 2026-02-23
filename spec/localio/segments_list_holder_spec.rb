require 'localio/segments_list_holder'

RSpec.describe SegmentsListHolder do
  subject(:holder) { SegmentsListHolder.new('en') }

  it { expect(holder.language).to eq('en') }
  it { expect(holder.segments).to be_empty }

  describe '#get_binding' do
    it 'returns a Binding' do
      expect(holder.get_binding).to be_a(Binding)
    end

    it 'exposes @language in the binding' do
      expect(eval('@language', holder.get_binding)).to eq('en')
    end

    it 'exposes @segments in the binding' do
      expect(eval('@segments', holder.get_binding)).to eq([])
    end
  end
end
