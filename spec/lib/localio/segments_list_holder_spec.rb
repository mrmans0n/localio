require 'spec_helper'

RSpec.describe SegmentsListHolder do
  let(:segment_list_holder) { SegmentsListHolder.new(:en)}

  def populate_segments(terms)
    terms.each do |key, translation|
      segment = Segment.new(key, translation, :en)
      segment_list_holder.segments << segment
    end
  end

  describe "#create_nested_hash" do
    it "returns a nested hash for a multi-part key" do
      segments = {"kanine_dog_chihuahua" => "Ulla"}
      populate_segments(segments)
      expect(segment_list_holder.create_nested_hash).to eq({"kanine"=>{"dog"=>{"chihuahua"=>"Ulla"}}})
    end

    it "returns a nested hash for a multi-part key with multiple segments" do
      segments = {"kanine_dog_chihuahua" => "Ulla", "kanine_dog_pug" => "Wilbur", "feline_cat" => "Teeny Tiny" }
      populate_segments(segments)
      expect(segment_list_holder.create_nested_hash).to eq({"kanine"=>{"dog"=>{"chihuahua"=>"Ulla", "pug" => "Wilbur"}}, "feline" => {"cat" => "Teeny Tiny"}})
    end

    it "skips an entry if it cannot be nested" do
      segments = {"kanine" => "hound", "kanine_dog_chihuahua" => "Ulla" }
      populate_segments(segments)
      expect(segment_list_holder.create_nested_hash).to eq({"kanine"=>"hound"})
    end
  end
end
