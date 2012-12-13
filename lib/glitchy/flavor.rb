# encoding: utf-8

module Glitchy
  module Flavor
    class << self
      def exists? name
        class_name = camelcase name.to_s
        exist = true
        begin
          self.const_get class_name
        rescue NameError
          exist = false
        end
        return exist
      end

      def get name
        klass = self.const_get camelcase(name.to_s)
        klass.new
      end

      def camelcase string
        string.gsub(/(^\w|_\w)/){|s| s.gsub('_', '').upcase }
      end
    end
  end
end

# TODO: autoload glitchy/flavor/*
require 'glitchy/flavor/jpeg'
require 'glitchy/flavor/png'
require 'glitchy/flavor/tiff'
require 'glitchy/flavor/gif'

