#encoding: utf-8
require 'zlib'
require 'uri'

module Glitchy
  class Image
    attr_accessor :data
    attr_reader :format, :size

    def initialize(source, data_length=nil)
      if source.kind_of? NSBitmapImageRep
        bitmap = source
      elsif source.kind_of? NSData
        bitmap = self.bitmap(source)
      elsif source.kind_of? String
        uri = begin
                URI(source)
              rescue URI::InvalidURIError
                raise "Image source must be valid URI or file path."
              end
        if uri.scheme.nil?
          if FileTest.file? source
            nsdata = NSData.alloc.initWithContentsOfFile source
            bitmap = NSBitmapImageRep.imageRepWithData nsdata
          else
            raise "Could not open file: #{source}"
          end
        elsif uri.scheme == 'http' || uri.scheme == 'https'
          url = NSURL.URLWithString source
          nsdata = NSData.alloc.initWithContentsOfURL url
          bitmap = NSBitmapImageRep.imageRepWithData nsdata
        end
      else
        raise "Image source must be BitmapImageRep, CGImageRef, Filepath and URL."
      end
      # get type and data from bitmap.
      @format = get_sym_format bitmap.bitmapFormat
      @data = bitmap.representationUsingType(bitmap.bitmapFormat, properties:nil)
      @size = bitmap.size
    end

    def glitch(flavor, flavor_opt={})
      nsdata = if flavor.kind_of? Flavor::Base
                 flavor.glitch(self, flavor_opt)
               elsif Flavor.exists(flavor)
                 Flavor.get(flavor, flavor_opt).glitch(self)
               end
      swap(nsdata)
    end

    def swap(nsdata)
      @data   = nsdata
      bitmap = bitmap(nsdata)
      @format = bitmap.bitmapFormat
      @size   = bitmap.size
    end

    def bitmap
      NSBitmapImageRep.imageRepWithData @data
    end

    # get bytes.
    def [](range_or_start, length=nil)
      range, size = if range_or_start.kind_of? Range
                      [nsrange(range_or_start), range_or_start.to_a.length]
                    else
                      [nsrange(range_or_start, length), length]
                    end
      buffer = Pointer.new(:char, size)
      @data.getBytes(buffer, range:range)
      buffer
    end

    def pointer_to_uint32 pointer
      string = ''
      string += [pointer[0]].pack('C')
      string += [pointer[1]].pack('C')
      string += [pointer[2]].pack('C')
      string += [pointer[3]].pack('C')
      string.unpack('N').first.to_i
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

    def pointer_to_s(pointer)
      pointer_to_array(pointer).pack('C*').to_s
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

    private

    def get_format(symbol)
      case symbol
      when :tiff
        NSTIFFFileType
      when :bmp
        NSBMPFileType
      when :gif
        NSGIFFileType
      when :jpeg
        NSJPEGFileType
      when :png
        NSPNGFileType
      when :jpeg2000
        NSJPEG2000FileType
      else
        raise "Unknown format"
      end
    end

    def get_sym_format(constant)
      case constant
      when NSTIFFFileType
        :tiff
      when NSBMPFileType
        :bmp
      when NSGIFFileType
        :gif
      when NSJPEGFileType
        :jpeg
      when NSPNGFileTYpe
        :png
      when NSJPEG2000FileType
        :jpeg2000
      else
        raise "Unkonwn format."
      end
    end

  end
end

