require 'spec_helper'

RSpec.describe IosWriter do
  it "inserts the correct string parameter notation" do
    string = "Hello, <s$1> and welcome to the app!"
    expect(described_class.ios_parsing(string)).to eq "Hello, %1$@ and welcome to the app!"
  end

  it "inserts the correct digit parameter notation" do
    string = "Hello, <d$1> and welcome to the app!"
    expect(described_class.ios_parsing(string)).to eq "Hello, %1$d and welcome to the app!"
  end

  it "inserts the correct char parameter notation" do
    string = "Hello, <c$1> and welcome to the app!"
    expect(described_class.ios_parsing(string)).to eq "Hello, %1$s and welcome to the app!"
  end
end
