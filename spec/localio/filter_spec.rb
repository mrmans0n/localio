require 'localio/term'
require 'localio/filter'

RSpec.describe Filter do
  let(:terms) do
    ['app_name', 'app_title', 'settings_title', 'settings_back', '[comment]'].map { |kw| Term.new(kw) }
  end

  describe '.apply_filter' do
    it 'returns all terms when no filters set' do
      expect(Filter.apply_filter(terms, nil, nil)).to eq(terms)
    end

    context 'with only filter' do
      it 'keeps terms matching the regex' do
        result = Filter.apply_filter(terms, { keys: 'app_' }, nil)
        expect(result.map(&:keyword)).to contain_exactly('app_name', 'app_title')
      end

      it 'returns empty array when nothing matches' do
        expect(Filter.apply_filter(terms, { keys: 'nonexistent' }, nil)).to be_empty
      end
    end

    context 'with except filter' do
      it 'excludes terms matching the regex' do
        result = Filter.apply_filter(terms, nil, { keys: 'settings_' })
        expect(result.map(&:keyword)).not_to include('settings_title', 'settings_back')
        expect(result.map(&:keyword)).to include('app_name', 'app_title')
      end
    end

    context 'with both filters' do
      it 'applies only first then except' do
        result = Filter.apply_filter(terms, { keys: 'app_' }, { keys: 'title' })
        expect(result.map(&:keyword)).to contain_exactly('app_name')
      end
    end
  end
end
