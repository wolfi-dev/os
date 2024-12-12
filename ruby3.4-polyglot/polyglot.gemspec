# polyglot.gemspec
lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'polyglot/version'

Gem::Specification.new do |spec|
  spec.name          = "polyglot"
  spec.version       = Polyglot::VERSION::STRING
  spec.authors       = ["Clifford Heath"]
  spec.email         = %w[clifford.heath@gmail.com]
  spec.summary       = %q{Augment 'require' to load non-Ruby file types}
  spec.description   = %q{The Polyglot library allows a Ruby module to register a loader
for the file type associated with a filename extension, and it
augments 'require' to find and load matching files.}
  spec.homepage      = "http://github.com/cjheath/polyglot"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*", "README.md", "LICENSE.txt"]
  spec.require_paths = ["lib"]
end

