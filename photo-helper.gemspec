# coding: utf-8
# frozen_string_literal: true
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'photo-helper/version'

Gem::Specification.new do |spec|
  spec.name          = "photo-helper"
  spec.version       = PhotoHelper::VERSION
  spec.authors       = ["Benjamin Caldwell"]
  spec.email         = ["caldwellbenjamin8@gmail.com"]

  spec.summary       = 'A tool to automatate my photo workflows'
  spec.homepage      = "https://github.com/benjamincaldwell/photo-helper"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "minitest-reporters"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "rubocop"

  spec.add_dependency "thor"
  spec.add_dependency "mini_magick"
  spec.add_dependency "ejson"
  spec.add_dependency "oauth"
  spec.add_dependency "mimemagic"
  spec.add_dependency "parallel"
  spec.add_dependency "ruby-progressbar"
end
