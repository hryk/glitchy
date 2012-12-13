# encoding: utf-8
require 'control_tower'
require 'rack'

module Glitchy

  class Server
    attr_reader :options

    def initialize(options)
      [:screen, :output, :server].each do |k|
        options.delete k
      end
      @options = options
    end

    def applicationDidFinishLaunching(notification)
      server_opts = {:host => "localhost",
                     :port => 9999,
                     :concurrent => true}
      queue = Dispatch::Queue.concurrent(:default)
      queue.async {
        ControlTower::Server.new(self,server_opts).start
      }
      NSLog("Glitch server started. http://#{server_opts[:host]}:#{server_opts[:port]}")
      NSLog("Example: http://#{server_opts[:host]}:#{server_opts[:port]}/screens")
    end

    def call(env)
      req = Rack::Request.new env
      glitch_opts = normalize_options(req.params)
      code, response = 200, ""
      NSLog("#{req.request_method}: #{req.path_info}")

      if req.path_info =~ /\/screens\/{0,1}$/
        glitch_opts[:screen] = :all
        NSLog("glitch: #{glitch_opts.inspect}")
        Glitchy::Screen.glitch glitch_opts
        response = "Glitched."
      elsif req.path_info =~ /\/screens\/(\d+?)$/
        glitch_opts[:screen] = $1.to_i
        NSLog("glitch: #{glitch_opts.inspect}")
        Glitchy::Screen.glitch glitch_opts
        response = "Screen #{glitch_opts[:screen]} Glitched."
      else
        NSLog(req.fullpath)
        code     = 404
        response = "Try /screens/ or /screens/0 "
      end
      # Return Response.
      [
        code,
        {"Content-Type" => "text/html;charset=utf-8"},
        response
      ]
    rescue => e
      puts e
      puts e.backtrace
      [500, {"Content-Type" => "text/html"}, "Error."]
    end

    protected

    def normalize_options(params)
      opt = @options.merge Hash[params.map{|k, v|
        if k == 'flavors'
          v = v.split(',')
        end
        [k.to_sym, v]
      }]
    end

  end
end
