#!/usr/bin/env ruby
# frozen_string_literal: true

require "rubygems"
Gem.instance_variable_set(:@ruby, ENV["RUBY"]) if ENV["RUBY"]

load Gem.activate_bin_path("bundler", "bundle")
