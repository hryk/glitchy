# encoding: utf-8

module Glitchy
  module Flavor

    # == Glitch::Flavor::Base
    #
    class Base
      def bitmap_image data
        NSBitmapImageRep.imageRepWithData data
      end
    end

  end
end

