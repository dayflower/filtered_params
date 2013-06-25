require 'gem' unless defined?(Gem)
require 'bundler/setup'
Bundler.require :default

require 'test/unit'
require 'active_support/test_case'

require 'filtered_params'
