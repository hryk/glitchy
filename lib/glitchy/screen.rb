# encoding: utf-8

module Glitchy
  # == Glitch::Screen
  #
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
        screen.write if options[:output]
      end

      sleep options[:time] if options[:time]
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
      @capture = NSBitmapImageRep.alloc.initWithCGImage(image)
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

    def show_image(image)
      image_view = NSImageView.alloc.initWithFrame @rect
      image_view.setImage image
      image_view.enterFullScreenMode @window.screen, withOptions:nil
      image_view
    end

    def test(image)
      NSLog("Glitch::Screen#show")
    end

    # NSApplicationで使う場合のメソッドとスクリプトで使う場合のメソッドは分けた方がよさそう。
    def show
      generate_glitched_data
      image = NSImage.alloc.initWithData @glitched_data
      NSLog("Glitch::Screen#show")
      if !image.nil? && image.isValid
        if NSThread.isMainThread
          NSLog("This is main thread")
          image_view = self.show_image(image)
          @window.orderFrontRegardless
          @window.setContentView image_view
        else
          NSLog("This is not main thread")
          image_view = self.show_image(image)
          main = Dispatch::Queue.main
          main.after(1) {
            image_view.exitFullScreenModeWithOptions nil
            @window.close
            NSApplication.sharedApplication.hide nil
          }
        end
      else
        raise "Failed to load image."
      end
    end

    def write
      image = NSBitmapImageRep.imageRepWithData @glitched_data
      raise "Failed to load image." if image.nil?
      data = image.representationUsingType(NSPNGFileType, properties:nil)
      data.writeToFile "#{ENV['HOME']}/Desktop/GlitchedCapture_#{@number}.png", atomically:false
    end

    protected

    def init_window
      @rect   = NSScreen.screens[@number].frame()
      @window = NSWindow.alloc.initWithContentRect(@rect,
                                                   styleMask:NSBorderlessWindowMask,
                                                   backing:NSBackingStoreBuffered,
                                                   defer:false)
      @window.setBackgroundColor(NSColor.clearColor)
      @window.setOpaque false
    end

    def generate_glitched_data
      @glitched_data = @capture # initialize
      @flavors.each_with_index do |f, i|
        @glitched_data = f.glitch @glitched_data, (i == (@flavors.length - 1))
      end
    end

  end
end
