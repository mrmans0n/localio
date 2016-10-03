require 'spec_helper'

RSpec.describe OegWriter do
  it "inserts the correct string parameter notation" do
    string = "No search results in <s$1> for <s$2>"
    expect(described_class.oeg_parsing(string)).to eq "No search results in %@1 for %@2"
  end

  it "inserts the correct digit parameter notation" do
    string = "<d$1> characters remaining of <d$2>"
    expect(described_class.oeg_parsing(string)).to eq "%@1 characters remaining of %@2"
  end

  it "escapes triple quotes" do
    string = 'No search results in <s$1> for ""<s$2>""'
    expect(described_class.oeg_parsing(string)).to eq 'No search results in %@1 for \"%@2\"'
  end

end
