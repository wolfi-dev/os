# bouncy-castle-java.gemspec
Gem::Specification.new do |s|
  s.name        = 'bouncy-castle-java'
  s.version     = '1.5.0146.1'
  s.author      = 'Hiroshi Nakamura'
  s.email       = 'nahi@ruby-lang.org'
  s.homepage    = 'http://github.com/nahi/bouncy-castle-java/'
  s.summary     = 'Gem redistribution of Bouncy Castle jars'
  s.description = 'Gem redistribution of "Legion of the Bouncy Castle Java cryptography APIs" jars at http://www.bouncycastle.org/java.html'
  s.files       = ['README', 'LICENSE.html'] + Dir.glob('lib/**/*')
  s.platform    = Gem::Platform::RUBY
  s.require_path = 'lib'

  s.add_runtime_dependency 'rubygems', '~> 3.0'
  # Add any other runtime dependencies here

  s.requirements << 'RubyGems version >= 3.0'

  s.add_development_dependency 'rake', '~> 13.0'

  s.metadata = {
    'source_code_uri' => 'http://github.com/nahi/bouncy-castle-java/',
    'bug_tracker_uri' => 'http://github.com/nahi/bouncy-castle-java/issues'
  }

  s.license = 'MIT'  # Adjust the license as needed
end
