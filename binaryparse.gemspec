Gem::Specification.new do |s|
  s.name = "binaryparse"
  s.version = "1.1.2"
  s.author = "Patrick Hurley"
  s.email = "phurley@gmail.com"
  s.homepage = "http://binaryparse.rubyforge.org/"
  s.platform = Gem::Platform::RUBY
  s.summary = "Binaryparse is a simple Ruby DSL to parse semi-complicated binary structures. This includes structures dynamic in length, which cannot be handled by DL::Struct or BitStructEx."
  s.description = "Binaryparse is a simple Ruby DSL to parse semi-complicated binary structures. This includes structures dynamic in length, which cannot be handled by DL::Struct or BitStructEx. It is similar to ActiveRecord in syntax"
  
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
  files << "README.md"
  files << "binaryparse.gemspec"
  s.files = files
  
  s.has_rdoc = true
end
