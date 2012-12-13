# encoding: utf-8
require 'glitchy/flavor/base'

module Glitchy
  module Flavor
    # == Glitch::Flavor::Gif
    #
    class Gif < Base
      def glitch bitmap, finalize=false
        data   = bitmap.representationUsingType(NSGIFFileType, properties:nil)
        10.times.each do
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
