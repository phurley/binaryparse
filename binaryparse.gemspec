require 'rubygems'

spec = Gem::Specification.new do |s|
  s.name = "binaryparse"
  s.version = "1.0.1"
  s.author = "Patrick Hurley"
  s.email = "phurley@gmail.com"
  s.homepage = "http://binaryparse.rubyforge.org/"
  s.platform = Gem::Platform::RUBY
  s.summary = "Binaryparse is a simple Ruby DSL to parse semi-complicated binary structures. This includes structures dynamic in length, which cannot be handled by DL::Struct or BitStructEx."
  s.description = "Binaryparse is a simple Ruby DSL to parse semi-complicated binary structures. This includes structures dynamic in length, which cannot be handled by DL::Struct or BitStructEx."
  
  files = []
  files << "examples"
  files << "lib"
  files << "test"
  files << "examples/cmasqls.rb"
  files << "examples/readme.txt"
  files << "examples/voter.rb"
  files << "lib/blocker.rb"
  files << "lib/buffered_io.rb"
  files << "test/test_blocker.rb"
  s.files = files
  
  s.autorequire = "binaryparse"
  s.has_rdoc = true
end

if  __FILE__ == $PROGRAM_NAME
  Gem::manage_gems
  Gem::Builder.new(spec).build
end
