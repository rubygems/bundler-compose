# frozen_string_literal: true

require "bundler"
require "bundler/cli"
require_relative "compose/cli"
require_relative "compose/composer"
require_relative "compose/version"

module Bundler
  module Compose
    class Error < BundlerError
      status_code 99
    end
    # Your code goes here...
  end
end
