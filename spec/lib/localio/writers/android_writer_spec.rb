require 'spec_helper'

RSpec.describe AndroidWriter do
  it "makes the keys XML safe" do
    string = "I'm a string that has symbols & is <really> bad for XML"
    expect(described_class.android_parsing(string)).to eq "I\\'m a string that has symbols &amp; is &lt;really&gt; bad for XML"
  end

  it "inserts the correct parameter notation" do
    string = "Hello, <$1> and welcome to the app!"
    expect(described_class.android_parsing(string)).to eq "Hello, %1$s and welcome to the app!"
  end
end
