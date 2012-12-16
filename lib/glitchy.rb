# encoding: utf-8

framework 'Cocoa'
framework 'ApplicationServices'

require 'glitchy/image'
require 'glitchy/flavor'
require 'glitchy/screen'
require 'glitchy/server'

module Glitchy
  VERSION = '0.1.0'
  class << self
    def app
      NSApplication.sharedApplication
    end
  end
end

