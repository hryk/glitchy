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
#   * 中間ファイル出すのやめた
#
#

framework 'Cocoa'
framework 'ApplicationServices'

class ScreenCapture
  attr_reader :window
  attr_reader :screen_rect

  def initialize
    @screen_rect = NSScreen.mainScreen.frame()
    @window = NSWindow.alloc.initWithContentRect(@screen_rect,
                                                styleMask:NSBorderlessWindowMask,
                                                backing:NSBackingStoreBuffered,
                                                defer:false)
    @window.setBackgroundColor(NSColor.blackColor)
  end

  def capture
    image = CGWindowListCreateImage(NSRectToCGRect(@screen_rect),
                                    KCGWindowListOptionOnScreenOnly,
                                    KCGNullWindowID,
                                    KCGWindowImageDefault)
    bitmapRep = NSBitmapImageRep.alloc.initWithCGImage(image)
    blob = bitmapRep.representationUsingType(NSJPEGFileType, properties:nil)
    return blob
  end

  def glitch blob
    byte_length = blob.length
    100.times.each do
      target = (rand blob.length).to_i
      blob.bytes[target] = 0
    end
    return blob
  end

  def show_fullscreen blob
    image_to_show = NSImage.alloc.initWithData(blob)
    if image_to_show.nil?
      puts "Failed to load glitch.";
      exit;
    end
    image_view = NSImageView.alloc.initWithFrame @screen_rect
    image_view.setImage image_to_show
    image_view.enterFullScreenMode @window.screen, withOptions:nil
    @window.orderFrontRegardless
    @window.setContentView image_view
    sleep 2
  end
end

app = NSApplication.sharedApplication
screenCapture = ScreenCapture.new
screenCapture.show_fullscreen screenCapture.glitch screenCapture.capture
