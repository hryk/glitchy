require 'spec_helper'

describe Glitchy::Screen do
  subject { @screen = Glitchy::Screen.new 0 }

  before(:each) {
    subject.clear!
  }

  describe '#capture' do
    it 'returns NSBitmapImageRep' do
      subject.capture.should be_an_instance_of(NSBitmapImageRep)
    end
  end

  describe '#initialize' do
    it 'set number of window' do
      subject.number.should be_equal(0)
    end

    it 'set a window object' do
      subject.window.should be_instance_of(NSWindow)
    end
  end
end
