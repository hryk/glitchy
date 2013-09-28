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
#    % ./glitch.rb --flavors gif
#
#    % ./glitch.rb --flavors gif,jpeg
#
#    # command line help
#    % ./glitch.rb -h
#
# * より高速に楽しみたい場合は
#
#    % macrubyc glitch.rb -o glitch
#    % ./glitch
#
# * 常用したい場合は (control_towerが必要です)
#
#    # Start glitch server.
#    % ./glitch.rb --server
#
#    # Glitchy all screens.
#    % curl http://localhost:9999/screens
#
#    # Glitchy selected screen.
#    % curl http://localhost:9999/screens/0
#
#    # Passing parameters.
#    % curl http://localhost:9999/screens?flavors=png,gif
#

require 'optparse'
require 'rubygems'
require 'glitchy'

app = NSApplication.sharedApplication

options = {
  :flavors     => ['jpeg'],
  :screen     => :all,
  :time       => 2,
  :output     => false,
  :server     => false
}

OptionParser.new do |opts|
  opts.banner = "Usage: glitch.rb [options]"
  opts.separator "Options:"

  opts.on("--server", TrueClass, "Start glitch server.") do |v|
    options[:server] = v
  end

  opts.on("-f", "--flavors x,y,z", Array,
          "Specify flavor of glitch.To use multiple flavors, separate by comma."
         ) do |list|
    options[:flavors] = list
  end

  opts.on("-s", "--screen N", Numeric,
          "Number of a target screen. (Default is all screens)") do |number|
    options[:screen] = number
  end

  opts.on("-o", "--output PATH", String,
          "Output filepath. Default is ~/Desktop/GlitchedCapture_[SCREENNUMBER].png") do |v|
    options[:output] = v
  end

  opts.on("-t", "--time N", Float,"Time to sleep (sec)") do |v|
    options[:time] = v
  end

  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end
end.parse!

if options[:server]
  if HAS_CTRL_TWR
    srv = Glitchy::Server.new options
    app.setDelegate(srv)
    app.run
  else
    abort "Server mode requires control_tower. To install it, type 'macgem install control_tower'"
  end
else
  Glitchy::Screen.glitch options
end
