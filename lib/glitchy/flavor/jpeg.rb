# encoding: utf-8
require 'glitchy/flavor/base'

module Glitchy
  module Flavor
    # == Glitch::Flavor::Jpeg
    #
    class Jpeg < Base
      # in     : NSBitmapImageRep
      # glitch : NSData ( by representationUsingType )
      # out    : NSBitmapImageRep ( by imageRepWithData )
      def glitch bitmap, finalize=false
        data   = bitmap.representationUsingType(NSJPEGFileType, properties:nil)
        100.times.each do
          pos = (rand data.length).to_i
          data.bytes[pos] = 0
        end
        if finalize
          data
        else
          bitmap_image(data)
        end
      end
    end
  end
end

