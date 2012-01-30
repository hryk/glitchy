#!/usr/bin/env macruby
#
# MacRubyで画面グリッチをフルスクリーン表示する
#
#   http://twitter.com/negipo/status/67572370247913473
#
# Tested with MacRuby-0.10
#
# References:
#
#   http://d.hatena.ne.jp/Watson/20100413/1271109590
#   http://www.cocoadev.com/index.pl?CGImageRef
#   http://d.hatena.ne.jp/Watson/20100823/1282543331
#   http://purigen.seesaa.net/article/137382769.html # how to access binary data in CGImageRef
#
#
# Changes
#
# 2012-01-30 @1VQ9
#
#   * flavor追加
#   * 中間ファイル出すのやめた
#

require 'optparse'

framework 'Cocoa'
framework 'ApplicationServices'

module Glitch

  module Flavor
    class << self
      def exists? name
        class_name = camelcase name.to_s
        exist = true
        begin
          self.const_get class_name
        rescue NameError => e
          exist = false
        end
        return exist
      end

      def get name
        klass = self.const_get camelcase(name.to_s)
        klass.new
      end

      def camelcase string
        string.gsub(/(^\w|_\w)/){|s| s.gsub('_', '').upcase }
      end
    end

    class Base
      def bitmap_image data
        NSBitmapImageRep.imageRepWithData data
      end
    end

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

    class Png < Base
    end

    class Tiff < Base
    end

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

    # ちゃんとグリッチできてない
    #
    # class Bmp < Base
    #   def glitch bitmap, finalize=false
    #     data   = bitmap.representationUsingType(NSBMPFileType, properties:nil)
    #     100.times.each do
    #       pos = (rand data.length).to_i
    #       data.bytes[pos] = 0
    #     end
    #     bitmap_image(data)
    #     if finalize
    #       data
    #     else
    #       bitmap_image(data)
    #     end
    #   end
    # end

  end

  class Screen
    attr_accessor :number, :rect, :window

    def self.glitch options={}
      screen = new options[:screen]
      screen.install_flavors options[:flavors]
      screen.show
      sleep options[:time]
    end

    def initialize screen_number
      @number = screen_number || 0
      @flavors = []
      init_window
    end

    def capture
      image = CGWindowListCreateImage(NSRectToCGRect(@rect),
                                      KCGWindowListOptionOnScreenOnly,
                                      KCGNullWindowID,
                                      KCGWindowImageDefault)
      bitmap = NSBitmapImageRep.alloc.initWithCGImage(image)
      return bitmap
    end

    def install_flavors flavors
      flavors.each do |name|
        flavor = if Flavor.exists? name
                   Flavor.get name
                 else
                   puts "No such flavor: #{name}"
                 end
        self << flavor
      end
    end

    def << flavor
      @flavors << flavor
    end

    def show
      generate_glitched_data
      image = NSImage.alloc.initWithData @glitched_data
      raise "Failed to load glitch." if image.nil?
      image_view = NSImageView.alloc.initWithFrame @rect
      image_view.setImage image
      image_view.enterFullScreenMode @window.screen, withOptions:nil
      @window.orderFrontRegardless
      @window.setContentView image_view
    end

    protected

    def init_window
      @rect   = NSScreen.screens[@number].frame()
      @window = NSWindow.alloc.initWithContentRect(@rect,
                                                   styleMask:NSBorderlessWindowMask,
                                                   backing:NSBackingStoreBuffered,
                                                   defer:false)
      @window.setBackgroundColor(NSColor.blackColor)
    end

    def generate_glitched_data
      bitmap = capture
      @flavors.each_with_index do |f, i|
        @glitched_data = if !@glitched_data.nil?
                           if i == (@flavors.length - 1)
                             f.glitch @glitched_data, true
                           else
                             f.glitch @glitched_data
                           end
                         else
                           if i == (@flavors.length - 1)
                             f.glitch bitmap, true
                           else
                             f.glitch bitmap
                           end
                         end
      end
    end

  end
end

# main program


app = NSApplication.sharedApplication

options = {
  :flavors     => ['jpeg'],
  :screen     => 0,
  :time       => 2
}

OptionParser.new do |opts|
  opts.banner = "Usage: glitch.rb [options]"
  opts.separator "Options:"

  opts.on("-f", "--flavors x,y,z", Array, "Specify flavor of glitch.To use multiple flavors, separate by comma.") do |list|
    options[:flavors] = list
  end

  opts.on("-s", "--screen N", Numeric, "Number of a target screen.") do |number|
    puts number
    options[:screen] = number
  end

  opts.on("-t", "--time N", Integer,"Time to sleep (sec)") do |v|
    options[:time] = v
  end

  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end

  opts.on("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

Glitch::Screen.glitch options

