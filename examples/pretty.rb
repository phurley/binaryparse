require 'pp'
require 'lib/blocker.rb'

class BBTest1 < BinaryBlocker::Blocker
  has_one :foo, :int16
  has_one :bar, :int32
  has_one :bar1, :int32
  has_one :bar2, :int32
  has_one :bar3, :int32
  has_one :bar4, :int32

  def me2
    self.class.to_s
  end
end

b = BBTest1.new

puts "Inspect: #{b.inspect}"
pp b
