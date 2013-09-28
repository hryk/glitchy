# encoding: utf-8

framework 'Cocoa'
framework 'ApplicationServices'
framework 'CoreGraphics'

require 'glitchy/image'
require 'glitchy/flavor'
require 'glitchy/screen'
module Glitchy
  VERSION = '0.1.0'
  begin
    require 'glitchy/server'
  rescue LoadError
    SERVER_OK = false
  else
    SERVER_OK = true
  end
  class << self
    def app
      NSApplication.sharedApplication
    end
  end
end

