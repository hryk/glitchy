require 'spec_helper'

describe Glitchy::Screen do
  subject {
     @screen = Glitchy::Screen.new 0
  }
  it 'capture screen image' do
    subject.capture.should be_an_instance_of(NSBitmapImageRep)
  end
end
