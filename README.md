glitchy
-------

A tiny tool for glitch displays. Only on the [MacRuby](http://macruby.org).

### Installation

    % sudo macgem install glitchy

### Usage

To glitch your display, just type:

    % glitch.rb

`flavors` option changes type of glitch.

    % glitch.rb --flavors png

Available flavors are below.

- jpeg (default)
- png
- gif

`flavors` option accept comma seperated multiple values.

    % glitch.rb --flavors gif,jpeg

`help` option shows description of flags.

    % glitch.rb -h

You can speed up glitchy with [rubygems-compile](https://github.com/ferrous26/rubygems-compile).

    % sudo macgem install rubygems-compile
    % sudo macgem compile glitchy

`glitchy` runs as server with `--server` option.

    % glitch.rb --server [--host HOSTNAME] [--port PORT]

glitchy server cause glitch on displays in response to HTTP GET request.

    % curl http://localhost:9999/screens
    
    % curl http://localhost:9999/screens/0
    
    % curl http://localhost:9999/screens?flavors=png

### API

Glitchy::Server
Glitchy::Glitchable
  Glitchy::Screen
  Glitchy::File
Glitchy::Flavor
  Glitchy::Flavor::Jpeg
  Glitchy::Flavor::Gif
  Glitchy::Flavor::Png
  TODO
  Glitchy::Flavor::BMP
  Glitchy::Flavor::Tiff
  Glitchy::Flavor::Webp
  Glitchy::Flavor::4BC
  Glitchy::Flavor::BASCII
  Glitchy::Flavor::BLINX
  Glitchy::Flavor::CCI
  Glitchy::Flavor::MCF
  Glitchy::Flavor::USPEC
  Glitchy::Flavor::XFF

### Development

use [rbenv-macruby](https://github.com/brettg/rbenv-macruby) to manage macruby versions and gems.

### References

- http://twitter.com/negipo/status/67572370247913473
- http://d.hatena.ne.jp/Watson/20100413/1271109590
- http://www.cocoadev.com/index.pl?CGImageRef
- http://d.hatena.ne.jp/Watson/20100823/1282543331
- http://purigen.seesaa.net/article/137382769.html # how to access binary data in CGImageRef
- http://www.jarchive.org/akami/aka018.html (glitchpng.rb)

