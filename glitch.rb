#!/usr/bin/env macruby
#
# MacRubyで画面グリッチをフルスクリーン表示する
#
#   http://twitter.com/negipo/status/67572370247913473
#
# ## Usage
#
#    ./glitch.rb
#
#    # gif flavor
#    ./glitch.rb --flavors gif
#
#    ./glitch.rb --flavors gif,jpeg
#
#    # command line help
#    ./glitch.rb -h
#
# * より高速に楽しみたい場合は
#
#    macrubyc glitch.rb -o glitch
#    ./glitch
#
# Tested with MacRuby-0.10
#
# ## Changes
#
# 2012-02-23 @1VQ9
#
#   * png flavor追加
#
# 2012-02-01 @1VQ9
#
#   * デフォルトで全ての画面をグリッチするようにした
#
# 2012-01-30 @1VQ9
#
#   * flavor追加
#   * 中間ファイル出すのやめた
#
# ## References:
#
#   http://d.hatena.ne.jp/Watson/20100413/1271109590
#   http://www.cocoadev.com/index.pl?CGImageRef
#   http://d.hatena.ne.jp/Watson/20100823/1282543331
#   http://purigen.seesaa.net/article/137382769.html # how to access binary data in CGImageRef
#   http://www.jarchive.org/akami/aka018.html (glitchpng.rb)
#

require 'optparse'
require 'zlib'

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
      # in     : NSBitmapImageRep
      # glitch : NSData ( by representationUsingType )
      # out    : NSBitmapImageRep ( by imageRepWithData )
      def glitch bitmap, finalize=false
        data   = bitmap.representationUsingType(NSPNGFileType, properties:nil)
        # header
        header = Pointer.new(:char, 8)
        data.getBytes(header, range:nsrange(0..7))
        head   = pointer_to_array(header).pack('C*')
        # Chunks
        # length(4), type(4), data(length), crc(4)
        state = :length
        pos   = 8
        buf_length = Pointer.new(:char, 4)
        buf_type   = Pointer.new(:char, 4)
        buf_crc    = Pointer.new(:char, 4)
        new_idat   = ""
        tail       = ""
        ihdr       = ""
        plte       = ""
        ihdr_flag  = false
        plte_flag  = false

        loop do
          break if pos >= data.length
          case state
          when :length
            data.getBytes(buf_length, range:nsrange(pos, 4))
            pos += 4
            state = :type
          when :type
            data.getBytes(buf_type, range:nsrange(pos, 4))
            pos += 4
            state = :data
          when :data
            len  = pointer_to_32uint(buf_length)
            type = pointer_to_array(buf_type).pack('C*').to_s
            if len > 0
              buf_data = Pointer.new(:char, len)
              data.getBytes(buf_data, range:nsrange(pos, len))
              case type
              when 'IDAT'
                new_idat += pointer_to_array(buf_data).pack('C*')
              when 'IHDR'
                ihdr = [len].pack('N') + 'IHDR' + pointer_to_array(buf_data).pack('C*')
                ihdr_flag = true
              when 'iCCP'
                plte = pointer_to_array(buf_length).pack('C*') + 'iCCP' + pointer_to_array(buf_data).pack('C*')
                plte_flag = true
              end
            end
            pos += len
            state = :crc
          when :crc
            if ihdr_flag
              data.getBytes(buf_crc, range:nsrange(pos, 4))
              ihdr += pointer_to_array(buf_crc).pack('C*')
              ihdr_flag = false
            elsif plte_flag
              data.getBytes(buf_crc, range:nsrange(pos, 4))
              plte += pointer_to_array(buf_crc).pack('C*')
              plte_flag = false
            end
            pos += 4
            state = :length
          else
          end
        end
        raw = Zlib::Inflate.new.inflate(new_idat)
        tmp_array = raw.unpack('C*')
        # Glitch
        (500..(tmp_array.size - 1)).each do |i|
          if (rand(10) % 6) > 2 && (tmp_array[i] == 3 || tmp_array[i] == 2)
            tmp_array[i] = rand(5).to_i
          end
        end
        cmp = Zlib::Deflate.deflate(tmp_array.pack('C*'))
        size = [cmp.size].pack('N')
        new_data = size + 'IDAT' + cmp
        crc = [Zlib.crc32(cmp, Zlib.crc32('IDAT'))].pack('N')
        iend = [0].pack('N') + 'IEND' + [Zlib.crc32('IEND')].pack('N')
        glitched_data = head + ihdr + plte + new_data + crc + iend
        data_array = glitched_data.unpack('C*')
        buffer = Pointer.new(:char, data_array.size)
        data_array.each_with_index do |d, i|
          buffer[i] = d
        end
        glitched_nsdata = NSData.alloc.initWithBytes(buffer, length: data_array.size)
        if finalize
          glitched_nsdata
        else
          bitmap_image(glitched_nsdata)
        end
      end

      protected

      def pointer_to_32uint(pointer)
        string = ''
        string += [pointer[0]].pack('C')
        string += [pointer[1]].pack('C')
        string += [pointer[2]].pack('C')
        string += [pointer[3]].pack('C')
        string.unpack("N").first.to_i
      end

      def pointer_to_array(pointer, cast=nil)
        array = []
        pos   = 0
        loop do
          begin
            array << pointer[pos]
          rescue
            break
          end
          pos += 1
        end
        array
      end

      def nsrange(range_or_start, len=nil)
        ns = NSRange.new
        if range_or_start.kind_of? Range
          ns.location = range_or_start.first
          ns.length = range_or_start.end - range_or_start.first + 1
        elsif range_or_start.kind_of? Fixnum
          ns.location = range_or_start
          ns.length   = len
        end
        ns
      end
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
    #     1000.times.each do
    #       pos = (rand data.length).to_i
    #     end
    #     if finalize then data else bitmap_image data end
    #   end
    # end

  end

  class Screen
    attr_accessor :number, :rect, :window

    def self.glitch options={}
      screens = []
      if options[:screen] == :all
        NSScreen.screens.length.times do |i|
          screens << new(i)
        end
      else
        screens << new(options[:screen])
      end
      screens.each do |screen|
        screen.install_flavors options[:flavors]
        screen.capture
      end
      screens.each do |screen|
          screen.show
      end
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
      @capture = bitmap
      return bitmap
    end

    def install_flavors flavors
      flavors.each do |name|
        flavor = if Flavor.exists? name
                   Flavor.get name
                 else
                   raise "No such flavor: #{name}"
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
      raise "Failed to load image." if image.nil?
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
      @glitched_data = @capture # initialize
      @flavors.each_with_index do |f, i|
        @glitched_data = f.glitch @glitched_data, (i == (@flavors.length - 1))
      end
    end

  end
end

# main program


app = NSApplication.sharedApplication

options = {
  :flavors     => ['jpeg'],
  :screen     => :all,
  :time       => 2
}

OptionParser.new do |opts|
  opts.banner = "Usage: glitch.rb [options]"
  opts.separator "Options:"

  opts.on("-f", "--flavors x,y,z", Array, "Specify flavor of glitch.To use multiple flavors, separate by comma.") do |list|
    options[:flavors] = list
  end

  opts.on("-s", "--screen N", Numeric, "Number of a target screen. (Default is all screens)") do |number|
    options[:screen] = number
  end

  opts.on("-t", "--time N", Float,"Time to sleep (sec)") do |v|
    options[:time] = v
  end

  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end

  opts.on("-h", "--help", "Show this message") do
    exit
  end
end.parse!

Glitch::Screen.glitch options
