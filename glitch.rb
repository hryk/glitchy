#!/usr/bin/env ruby
#
# MacRubyで画面グリッチをフルスクリーン表示する
#
#   http://twitter.com/negipo/status/67572370247913473
#
# Reference:
#   http://d.hatena.ne.jp/Watson/20100413/1271109590
#   http://www.cocoadev.com/index.pl?CGImageRef
#   http://d.hatena.ne.jp/Watson/20100823/1282543331
#
# Tested with MacRuby-0.9
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
    filename ||= "/tmp/#{Time.now.strftime('%Y-%m-%d-%H%M%S')}.png"
    image = CGWindowListCreateImage(NSRectToCGRect(@screen_rect),
                                    KCGWindowListOptionOnScreenOnly,
                                    KCGNullWindowID,
                                    KCGWindowImageDefault)
    bitmapRep = NSBitmapImageRep.alloc.initWithCGImage(image)
    blob = bitmapRep.representationUsingType(NSJPEGFileType, properties:nil)
    blob.writeToFile(filename, atomically:true)
    return filename
  end

  def glitch(filename)
    glitched_file = '/tmp/glitched_capture.jpg'
    %x[cat #{filename} | perl -npe 's/0/9/g' > #{glitched_file}]
    return glitched_file
  end

  def show_fullscreen(filename)
    image_to_show = NSImage.alloc.initWithContentsOfFile(filename)
    if image_to_show.nil?
      puts "Failed to load glitch.: #{filename}";
      exit;
    end
    image_view = NSImageView.alloc.initWithFrame @screen_rect
    image_view.setImage image_to_show
    image_view.enterFullScreenMode @window.screen, withOptions:nil
    # フルスクリーン表示する
    @window.orderFrontRegardless
    @window.setContentView image_view
    sleep 2
  end
end

app = NSApplication.sharedApplication
screenCapture = ScreenCapture.new
screenCapture.show_fullscreen screenCapture.glitch screenCapture.capture
