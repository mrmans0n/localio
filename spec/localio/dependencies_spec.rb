RSpec.describe 'Localio runtime dependencies' do
  let(:gemspec) { Gem::Specification.load(File.expand_path('../../localio.gemspec', __dir__)) }

  it 'requires an Addressable release with the URI security fixes' do
    dependency = gemspec.runtime_dependencies.find { |candidate| candidate.name == 'addressable' }

    expect(dependency).not_to be_nil
    expect(dependency.requirement.satisfied_by?(Gem::Version.new('2.9.0'))).to be(false)
    expect(dependency.requirement.satisfied_by?(Gem::Version.new('2.9.1'))).to be(true)
    expect(dependency.requirement.satisfied_by?(Gem::Version.new('2.10.0'))).to be(true)
    expect(dependency.requirement.satisfied_by?(Gem::Version.new('3.0.0'))).to be(false)
  end

  it 'requires a Nokogiri release with the XML and HTML security fixes' do
    dependency = gemspec.runtime_dependencies.find { |candidate| candidate.name == 'nokogiri' }

    expect(dependency).not_to be_nil
    expect(dependency.requirement.satisfied_by?(Gem::Version.new('1.19.4'))).to be(false)
    expect(dependency.requirement.satisfied_by?(Gem::Version.new('1.19.5'))).to be(true)
    expect(dependency.requirement.satisfied_by?(Gem::Version.new('1.19.7'))).to be(true)
    expect(dependency.requirement.satisfied_by?(Gem::Version.new('2.0.0'))).to be(false)
  end
end
