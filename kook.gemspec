# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kook/version'

Gem::Specification.new do |spec|
  spec.name          = "kook"
  spec.version       = Kook::VERSION
  spec.authors       = ["Glenn Y. Rolland"]
  spec.email         = ["glenux@glenux.net"]
  spec.summary       = %q{Kook is a helper for opening your projects environments in tabs of KDE Konsole}
  #spec.description   = %q{TODO: Write a longer description. Optional.}
  spec.homepage      = "http://github.com/glenux/kook"
  spec.license       = "MIT"

  spec.rubyforge_project = "kook"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.bindir = 'bin'
  spec.post_install_message = "Thanks for installing!"

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
#  spec.add_development_dependency "pry"
#  spec.add_development_dependency "rm-readline"

  spec.add_runtime_dependency "thor"
  spec.add_runtime_dependency "colorize"
end
