require 'spec_helper'

RSpec.describe AndroidWriter do
  it "makes the keys XML safe" do
    string = "I'm a string that has symbols & is <really> bad for XML"
    expect(described_class.android_parsing(string)).to eq "I\\'m a string that has symbols &amp; is &lt;really&gt; bad for XML"
  end

  it "inserts the correct string parameter notation" do
    string = "Hello, <s$1> and welcome to the app!"
    expect(described_class.android_parsing(string)).to eq "Hello, %1$s and welcome to the app!"
  end

  it "inserts the correct digit parameter notation" do
    string = "Hello, <d$1> and welcome to the app!"
    expect(described_class.android_parsing(string)).to eq "Hello, %1$d and welcome to the app!"
  end

  it "handles two-character parameter notation" do
    string = "Hello, <tY$1> and welcome to the app!"
    expect(described_class.android_parsing(string)).to eq "Hello, %1$tY and welcome to the app!"
  end

end
