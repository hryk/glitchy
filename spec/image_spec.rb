require 'spec_helper'

describe Glitchy::Image do

  describe("#initialize") do
    it 'initialize with BitmapImageRep' do
      data = NSData.alloc.
        initWithContentsOfFile "spec/data/cc.logo.large.png"
      bitmap  = NSBitmapImageRep.imageRepWithData data
      Glitchy::Image.new(bitmap).should be_an_instance_of(Glitchy::Image)
    end

    it 'initialize with Jpeg File' do
      Glitchy::Image.new("spec/data/cc.logo.large.jpg"
                        ).should be_an_instance_of(Glitchy::Image)
    end

    it 'initialize with Png File' do
      Glitchy::Image.new("spec/data/cc.logo.large.jpg"
                        ).should be_an_instance_of(Glitchy::Image)
    end

    it 'initialize with URL' do
      Glitchy::Image.new("http://dl.dropbox.com/u/59046/sushi.png").
                    should be_an_instance_of(Glitchy::Image)
    end

    it 'initialize with https URL' do
      Glitchy::Image.new("http://dl.dropbox.com/u/59046/sushi.png").
                    should be_an_instance_of(Glitchy::Image)
    end
  end

  describe "binary handling functions" do
    subject { Glitchy::Image.new('spec/data/cc.logo.large.png') }
    it '#pointer_to_uint32' do
    end
    it '#pointer_to_array'
    it '#pointer_to_s' do
      subject.format.should eq(:png)
      pointer = subject[0,3]
      subject.pointer_to_s(pointer).should eq('PNG')
    end
    it '#nsrange with range'
    it '#nsrange with start and length'
  end

  describe "bitmap_image" do
    it "#bitmap" do
      image = Glitchy::Image.new("spec/data/cc.logo.large.jpg")
      image.bitmap.should be_an_instance_of(NSBitmapImageRep)
    end
  end

  describe "write down to files" do
    it "#write"
  end
end
