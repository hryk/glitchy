# -*- ruby -*-

require 'rubygems'
require 'hoe'

Hoe.plugin :git
Hoe.plugin :gemspec
Hoe.plugin :bundler

Hoe.spec 'glitchy' do
  developer 'hryk', 'hiroyuki@1vq9.com'
  license 'MIT'
  dependency "control_tower", ">= 1.0", :runtime
  self.history_file = 'Changes'
  self.readme_file = 'README.md'
  self.extra_dev_deps += [
    ["hoe-bundler", ">= 1.1"],
    ["hoe-gemspec", ">= 1.0"],
    ["hoe-git", ">= 1.4"],
  ]
  self.spec_extras = [
    ['platform', Gem::Platform::MACRUBY]
  ]
  self.urls = {
    'home' => "http://hryk.github.com/glitchy",
    'code' => "https://github.com/hryk/glitchy",
  }
end

# vim: syntax=ruby
