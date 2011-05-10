#!/usr/bin/env ruby
#
# MacRubyで高速にフルスクリーン表示する
#
# Reference:
#   http://d.hatena.ne.jp/Watson/20100413/1271109590
#   http://www.cocoadev.com/index.pl?CGImageRef
#   http://d.hatena.ne.jp/Watson/20100823/1282543331
#

framework 'Cocoa'
framework 'ApplicationServices'

CGRectInfinite = CGRect.new([-2.0e+500, 2.0e+500], [2.0e+500, 2.0e+500]) unless defined? (CGRectInfinite)

class ScreenCapture
  def fullscreen(filename=nil)
    filename ||= "#{Time.now.strftime('%Y-%m-%d-%H%M%S')}.png"
    rect = NSScreen.mainScreen.frame()
    window = NSWindow.alloc.initWithContentRect(rect,
                                                styleMask:NSBorderlessWindowMask,
                                                backing:NSBackingStoreBuffered,
                                                defer:false)
    window.setBackgroundColor(NSColor.blackColor)
    image = CGWindowListCreateImage(NSRectToCGRect(rect), KCGWindowListOptionOnScreenOnly, KCGNullWindowID, KCGWindowImageDefault)
    bitmapRep = NSBitmapImageRep.alloc.initWithCGImage(image)

    # bitmap_dataから新しくNSBitmapImageRepを作れない。。
    #
    # bitmap_data = bitmapRep.bitmapData.gsub(/0/, '9')
    # bp = bitmap_data.pointer
    # bp.cast!('*')
    # glitched = NSBitmapImageRep.alloc.initWithBitmapDataPlanes(bp,
    #                                                            pixelsWide:NSWidth(rect),
    #                                                            pixelsHigh:NSHeight(rect),
    #                                                            bitsPerSample:8,
    #                                                            samplesPerPixel:3,
    #                                                            hasAlpha:false,
    #                                                            isPlanar:true,
    #                                                            colorSpaceName:NSDeviceRGBColorSpace,
    #                                                            bytesPerRow:0,
    #                                                            bitsPerPixel:0)
    # Create an NSImage..

    ns_image = NSImage.alloc.init
    ns_image.addRepresentation bitmapRep # glitched
    image_view = NSImageView.alloc.initWithFrame(rect)
    image_view.setImage(ns_image)
    image_view.enterFullScreenMode(window.screen, withOptions:nil)
    window.setContentView(image_view)
    # フルスクリーン表示する
    window.orderFrontRegardless
    sleep 2
    contentView = window.contentView
  end

  # def save(image, filename)
  #   blob = bitmapRep.representationUsingType(NSPNGFileType, properties:nil)
  #   blob.writeToFile(filename, atomically:true)
  # end
  # private :save
end

app = NSApplication.sharedApplication
screenCapture = ScreenCapture.new
screenCapture.fullscreen()
