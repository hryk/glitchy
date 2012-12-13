# encoding: utf-8
require 'zlib'
require 'glitchy/flavor/base'

module Glitchy
  module Flavor

    # == Glitch::Flavor::Png
    #
    class Png < Base
      # in     : NSBitmapImageRep
      # glitch : NSData ( by representationUsingType )
      # out    : NSBitmapImageRep ( by imageRepWithData )
      def glitch bitmap, finalize=false
        data   = bitmap.representationUsingType(NSPNGFileType, properties:nil)

        # Convert raw bytes to glitchable bytes
        #   header    (png-header, image-header)
        #   raw_image (decompressed idat)
        #   iend      (IEND)
        header, raw_image, iend = extract_image data

        # Glitch
        glitched_image_bytes = glitch_image raw_image

        # Reconstruct image data
        glitched_nsdata = build_image header, glitched_image_bytes, iend

        if finalize
          glitched_nsdata
        else
          bitmap_image(glitched_nsdata)
        end
      end

      def glitch_image image_bytes
        # PNG filter method 0 defines five basic filter types:
        #
        #   http://www.libpng.org/pub/png/spec/1.2/PNG-Filters.html
        #
        #    Type    Name
        #
        #    0       None
        #    1       Sub
        #    2       Up
        #    3       Average
        #    4       Paeth
        #
        (0..(image_bytes.size - 1)).each do |i|
          #if (rand(10) % 6) > 2 && image_bytes[i] == 2
          #  image_bytes[i] = rand(5)
          if image_bytes[i] > 10 && image_bytes[i] < 17 && (rand(10) % 6) > 4
            image_bytes[i] = rand(255)
          end
        end
        image_bytes
      end

      protected

      def build_image head, image_bytes, iend
        compressed_image = Zlib::Deflate.deflate(image_bytes.pack('C*'))
        image_size       = [compressed_image.size].pack('N').unpack('C*')
        image_crc        = [Zlib.crc32(compressed_image, Zlib.crc32('IDAT'))].pack('N').unpack('C*')
        png_byte_array   = head + image_size + 'IDAT'.unpack('C*') + compressed_image.unpack('C*') + image_crc + iend
        buffer = Pointer.new(:char, png_byte_array.size)
        png_byte_array.each_with_index do |b, i|
          buffer[i] = b
        end
        NSData.alloc.initWithBytes(buffer, length:png_byte_array.size)
      end

      def extract_image nsdata
        buffer = {
          :head   => Pointer.new(:char, 8),
          :length => Pointer.new(:char, 4),
          :type   => Pointer.new(:char, 4),
          :crc    => Pointer.new(:char, 4)
        }
        byte_array = {
          :head   => [],
          :idat   => [],
          :ihdr   => [],
          :iccp   => [],
          :iend   => []
        }

        save_crc = nil
        state    = :length
        position = 8       # Skip PNG header

        # Get PNG header
        nsdata.getBytes(buffer[:head], range:nsrange(0, 8))
        byte_array[:head].concat pointer_to_array(buffer[:head])

        # Read chunks
        loop do
          break if position >= nsdata.length
          case state
          when :length
            nsdata.getBytes(buffer[:length], range:nsrange(position, 4))
            position += 4
            state    = :type
          when :type
            nsdata.getBytes(buffer[:type], range:nsrange(position, 4))
            position += 4
            state    = :data
          when :data
            data_length = pointer_to_uint32 buffer[:length]
            data_type   = pointer_to_s buffer[:type]

            if data_length > 0
              data_buffer = Pointer.new(:char, data_length)
              nsdata.getBytes(data_buffer, range:nsrange(position, data_length))

              case data_type
              when 'IDAT'
                byte_array[:idat].concat pointer_to_array(data_buffer)
              when 'IHDR'
                byte_array[:head].concat pointer_to_array(buffer[:length])
                byte_array[:head].concat pointer_to_array(buffer[:type])
                byte_array[:head].concat pointer_to_array(data_buffer)
                save_crc = :head
              when 'iCCP'
                byte_array[:iccp].concat pointer_to_array(buffer[:length])
                byte_array[:iccp].concat pointer_to_array(buffer[:type])
                byte_array[:iccp].concat pointer_to_array(data_buffer)
                save_crc = :iccp
              end
            elsif data_type == 'IEND'
              byte_array[:iend].concat pointer_to_array(buffer[:length])
              byte_array[:iend].concat pointer_to_array(buffer[:type])
              save_crc = :iend
            end
            position += data_length
            state = :crc
          when :crc
            if !save_crc.nil?
              nsdata.getBytes(buffer[:crc], range:nsrange(position, 4))
              byte_array[save_crc].concat pointer_to_array(buffer[:crc])
              save_crc = nil
            end
            position += 4
            state = :length
          end
        end

        # Decompress IDAT
        raw_image = Zlib::Inflate.new.inflate(byte_array[:idat].pack('C*')).unpack('C*')

        return [byte_array[:head], raw_image, byte_array[:iend]]
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
    end

  end
end
