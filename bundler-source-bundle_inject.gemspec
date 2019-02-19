lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "bundler/inject/version"

Gem::Specification.new do |spec|
  spec.name          = "bundler-source-bundle_inject"
  spec.version       = Bundler::Inject::VERSION
  spec.authors       = ["ManageIQ Authors"]

  spec.summary       = %q{Summary}
  spec.description   = %q{Description}
  spec.homepage      = "https://github.com/ManageIQ/bundler-inject"
  spec.license       = "Apache-2.0"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = []
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
