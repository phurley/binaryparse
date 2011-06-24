require 'blocker'
require 'stringio'
require 'test/unit' #unless defined? $ZENTEST and $ZENTEST

class TestBlocker < Test::Unit::TestCase
  class BBTest1 < BinaryBlocker::Blocker
    has_one :foo, :int16
    has_one :bar, :int32
  end
  
  def test_usage
    bb = BBTest1.new
    bb.foo = 32
    bb.bar = 24
    
    assert_equal(32, bb.foo)
    assert_equal(24, bb.bar)
  end

  class BBTest2 < BinaryBlocker::Blocker
    has_one :foo, :int16, :key => 42
    has_one :bar, :int32
  end

  def test_simple_valid
    bb = BBTest2.new
    bb.bar = 24

    assert_equal(24, bb.bar)
    assert(bb.valid?)
  end

  def test_round_trip
    bb = BBTest2.new
    bb.bar = 21
    buf = bb.block 

    bb2 = BBTest2.new
    bb2.deblock(StringIO.new(buf))
    assert_equal(bb2.foo, 42)
    assert_equal(bb2.bar, 21)

    bb3 = BBTest2.new(StringIO.new(buf))
    assert_equal(bb3.foo, 42)
    assert_equal(bb3.bar, 21)
  end

  def test_failed_deblock
    bb = BBTest2.new
    bb.bar = 21
    buf = bb.block
    buf[0] = 0.chr

    bb2 = BBTest2.new
    status = bb2.deblock(StringIO.new(buf))
    assert(!status)
    
    assert_raises(RuntimeError) do
      BBTest2.new(StringIO.new(buf))
    end
    
    io = StringIO.new(bb.block)
    assert(bb2.deblock(io))
    
    assert_equal(bb2.foo, 42)
    assert_equal(bb2.bar, 21)
    assert_equal(6, io.pos)    
  end
  
  class BBSub1 < BinaryBlocker::Blocker
    has_one :foo, :int16, :key => 42
  end
  
  class BBSub2 < BinaryBlocker::Blocker
    has_one :bar, :int16, :key => 21
  end
  
  class BBTest3 < BinaryBlocker::Blocker
    has_one_of :foo, [BBSub1, BBSub2]
  end

  def test_has_one_of
    bs1 = BBSub1.new
    buf = bs1.block
    bb = BBTest3.new(StringIO.new(buf))
    assert(bb)
    assert_equal(BBSub1, bb.foo.class)
    assert_equal(42, bb.foo.foo)
    
    bs2 = BBSub2.new
    io = StringIO.new(bs2.block)
    bb = BBTest3.new(io)
    assert(bb)
    assert_equal(BBSub2, bb.foo.class)
    assert_equal(21, bb.foo.bar)
    assert_equal(2, io.pos)
    
    bb.foo = bs1
    assert_equal(BBSub1, bb.foo.class)
    assert_equal(42, bb.foo.foo)
    
    buf = bb.block
    bb = BBTest3.new(buf)
    assert_equal(BBSub1, bb.foo.class)
    assert_equal(42, bb.foo.foo)
  end  
  
  class BBTest4 < BinaryBlocker::Blocker
    has_fixed_array :fooboo, 3, [BBSub1, BBSub2]
  end
  
  def test_fixed_array
    bs1 = BBSub1.new
    bs2 = BBSub2.new
    
    buf = bs1.block + bs2.block + bs1.block
    bb = BBTest4.new(buf)
    
    assert(bb)
    assert(bb.fooboo)
    assert(bb.fooboo[0].foo)
    assert_equal(42, bb.fooboo[0].foo)
    assert_equal(21, bb.fooboo[1].bar)
    assert_equal(42, bb.fooboo[2].foo)
  end
  
  def test_building_fixed_array
    fa = BBTest4.new
    assert(fa)
    fa.fooboo[0] = BBSub1.new
    fa.fooboo[1] = BBSub2.new
    fa.fooboo[2] = BBSub1.new
    assert_equal(42, fa.fooboo[0].foo)
    assert_equal(21, fa.fooboo[1].bar)
    assert_equal(42, fa.fooboo[2].foo)
    
    buf = fa.block
    bb = BBTest4.new(buf)    
    assert(bb)
    assert(bb.fooboo)
    assert(bb.fooboo[0].foo)
    assert_equal(42, bb.fooboo[0].foo)
    assert_equal(21, bb.fooboo[1].bar)
    assert_equal(42, bb.fooboo[2].foo)

    assert_raises(RangeError) { bb.fooboo[-1] }
    assert_raises(RangeError) { bb.fooboo[3] }    
  end
  
  class BBTest5 < BinaryBlocker::Blocker
    has_counted_array :fooboo, :int16, [BBSub1, BBSub2]
  end
  
  def test_counted_array
    bb1 = BBSub1.new
    bb2 = BBSub2.new
    
    fa = BBTest5.new
    assert(fa)
    assert_equal(0, fa.fooboo.size)
    
    fa.fooboo << bb1
    assert_equal(1, fa.fooboo.size)
    
    fa.fooboo << bb1
    assert_equal(2, fa.fooboo.size)
    
    fa.fooboo << bb1
    assert_equal(3, fa.fooboo.size)
    
    fa.fooboo << bb2
    assert_equal(4, fa.fooboo.size)
    
    fa.fooboo << bb1
    assert_equal(5, fa.fooboo.size)
        
    assert_raises(RangeError) { fa.fooboo[-1] }
    assert_raises(RangeError) { fa.fooboo[5] }
    assert(fa.fooboo[4])
  end
  
  class BBTest6 < BinaryBlocker::Blocker
    has_one :a, BBTest1
    has_one :bar, :int32
  end
  
  def test_composing
    bb = BBTest6.new
    assert(bb)
    bb.a.foo = 1
    assert_equal(1, bb.a.foo)
    bb.a.bar = 2
    assert_equal(2, bb.a.bar)
    bb.bar = 1234
    assert_equal(1234, bb.bar)
    
    buf = bb.block
    assert_equal(10, buf.size)
    
    bb2 = BBTest6.new(buf)
    assert(bb2)
    assert_equal(1, bb2.a.foo)
    assert_equal(2, bb2.a.bar)
    assert_equal(1234, bb2.bar)
  end
  
  class BBTest7 < BinaryBlocker::Blocker
    has_bit_field :a, :uint32, [:fld1, 2, [:fld2, 3]]
  end
  
  def test_bitfield
    bb = BBTest7.new
    assert(bb)
    
    #assert(bb.a.fld1)
    bb.a.fld2 = 1
    assert_equal(8, bb.a.raw_value)
    bb.a.fld2 = 2
    assert_equal(16, bb.a.raw_value)
    bb.a.fld1 = 1
    assert_equal(17, bb.a.raw_value)
    
    buf = bb.block
    bb2 = BBTest7.new(buf)
    assert_equal(17, bb.a.raw_value)    
    assert_equal(1, bb.a.fld1)
    assert_equal(2, bb.a.fld2)
    
    assert_raises(NoMethodError) { bb.a.fld12 }
  end
  
  class BBString < BinaryBlocker::Blocker
    has_one :foo, :int16
    has_one :name, :string, :length => 20
    has_one :bar, :int32
  end

  def test_fixed_string
    b = BBString.new
    b.foo = 1
    b.name = "Patrick "
    b.bar = 42
    
    assert_equal(1, b.foo)
    assert_equal("Patrick ", b.name)
    assert_equal(42, b.bar)
    
    buf = b.block
    assert_equal(2 + 20 + 4, buf.size)
    
    b2 = BBString.new(buf)
    assert_equal(1, b2.foo)
    assert_equal("Patrick ", b2.name)
    assert_equal(42, b2.bar)    
  end
  
  class BBUTF16 < BinaryBlocker::Blocker
    has_one :foo, :int16
    has_one :name, :utf16, :length => 20
    has_one :bar, :int32
  end

  def test_utf16
    b = BBUTF16.new
    b.foo = 1
    b.name = "Patrick "
    b.bar = 42
    
    assert_equal(1, b.foo)
    assert_equal("Patrick ", b.name)
    assert_equal(42, b.bar)
    
    buf = b.block
    assert_equal(2 + 20 * 2 + 4, buf.size)
    
    b2 = BBUTF16.new(buf)
    assert_equal(1, b2.foo)
    assert_equal("Patrick ", b2.name)
    assert_equal(42, b2.bar)    
  end
  
  class BBPacked < BinaryBlocker::Blocker
    has_one :foo, :int16
    has_one :age, :packed, :length => 3
    has_one :bar, :int32
  end

  def test_packed_numbers
    b = BBPacked.new
    b.foo = 7
    b.age = 32
    b.bar = 3

    assert_equal(7, b.foo)
    assert_equal(32, b.age)
    assert_equal(3, b.bar)
    
    buf = b.block
    assert_equal(2 + 2 + 4, buf.size)
    
    b2 = BBPacked.new(buf)
    assert_equal(7, b2.foo)
    assert_equal(32, b2.age)
    assert_equal(3, b2.bar)    
  end

  class BBDate < BinaryBlocker::Blocker
    has_one :today, :date
  end
  
  def test_packed_date
    bdate = Date.civil(1967, 9, 30)
    b = BBDate.new
    b.today = bdate
    
    buf = b.block
    assert_equal(4, buf.size)
    
    b2 = BBDate.new(buf)
    assert_equal(bdate, b2.today)
  end
  
  class BBTime < BinaryBlocker::Blocker
    has_one :now, :time
  end
  
  def test_packed_datetime
    now = Time.local(1985, 5, 30, 7, 6, 5)
    b = BBTime.new
    b.now = now
    
    buf = b.block
    assert_equal(14 / 2, buf.size)
    
    b2 = BBTime.new(buf)
    assert_equal(now, b2.now)
  end 
  
  class ItemA < BinaryBlocker::Blocker
    has_one :iid, :int16, :key => 1
    has_one :name, :string, :length => 32
  end

  class ItemB < BinaryBlocker::Blocker
    has_one :iid, :int16, :key => 2
    has_one :name, :string, :length => 32
  end

  class BBList < BinaryBlocker::Blocker
    has_one :header, :int16
    has_list_of :items, [ItemA, ItemB]
    has_one :footer, :int16
  end
  
  def test_delimited_array
    b = BBList.new
    b.header = 19
    b.footer = 67
    
    ia = ItemA.new
    assert_equal(1, ia.iid)
    
    ib = ItemB.new
    ib.name = 'widget B'
    
    b.items << ia << ib << ia << ib << ib << ib
    assert_equal(6, b.items.size)
    
    buf = b.block
    assert_equal(2 + (2 + 32) * 6 + 2, buf.size)
    
    b2 = BBList.new(buf)
    assert_equal(19, b2.header) 
    assert_equal(67, b2.footer)
    
    assert_equal(6, b2.items.size)
    
    assert_equal(b2.items[0].iid, ia.iid) 
    assert_equal(b2.items[1].iid, ib.iid) 
    assert_equal(b2.items[2].iid, ia.iid) 
    assert_equal(b2.items[3].iid, ib.iid) 
    assert_equal(b2.items[4].iid, ib.iid) 
    assert_equal(b2.items[5].iid, ib.iid) 
    
    assert_equal(b2.items[0].name, ia.name)
    assert_equal(b2.items[1].name, ib.name)
    assert_equal(b2.items[2].name, ia.name)
    assert_equal(b2.items[3].name, ib.name)
    assert_equal(b2.items[4].name, ib.name)
    assert_equal(b2.items[5].name, ib.name) 
  end
  
  class BBDefaultTest < BinaryBlocker::Blocker
    has_one :foo, :int16, :default => 7
    has_one :bar, :int16
    has_one :str, :string, :length => 20, :default => 'troaeipo'
  end

  def test_default
    b = BBDefaultTest.new
    assert_equal(7, b.foo)
    assert_equal(nil, b.bar)
    assert_equal('troaeipo', b.str)
    
    b.foo = nil
    assert_equal(nil, b.foo)
    b.bar = 3
    
    buf = b.block
    
    b2 = BBDefaultTest.new(buf)
    assert_equal(0, b2.foo)
    assert_equal(3, b2.bar)
    assert_equal('troaeipo', b2.str)
  end

  class BBDateRecord < BinaryBlocker::Blocker
    has_one :date, :date
  end
  
  def test_null_dates
    t = BBDateRecord.new
    assert(buf = t.block)

    t2 = BBDateRecord.new(buf)
    assert(t2)
    assert_nil(t2.date)
  end

  class BBTimeRecord < BinaryBlocker::Blocker
    has_one :t, :time
  end
  
  def test_null_times
    t = BBTimeRecord.new
    assert(buf = t.block)

    t2 = BBTimeRecord.new(buf)
    assert(t2)
    assert_nil(t2.t)
  end
  
  class BBPackNumRecord < BinaryBlocker::Blocker
    has_one :p, :packed, :length => 2
  end
  
  def test_null_packed
    t = BBPackNumRecord.new
    assert(buf = t.block)

    t2 = BBPackNumRecord.new(buf)
    assert(t2)
    assert_equal(0, t2.p)
  end
  
  def test_big_packed
    t = BBPackNumRecord.new
    t.p = 200
    assert(buf = t.block)
    assert_equal(1, buf.size)

    t2 = BBPackNumRecord.new(buf)
    assert(t2)
    assert(t2.p < 100)
  end
  
  class Filler < BinaryBlocker::Blocker
    has_one :f, :uint8
  end
  
  class NullFillerTest < BinaryBlocker::Blocker
    has_fixed_array :fooboo, 3, [Filler]
  end
  
  def test_null_filler
    t = NullFillerTest.new
    assert(buf = t.block)
  end
  
  class BBSpaceString < BinaryBlocker::Blocker
    has_one :name, :sstring, :length => 10 
    has_one :last, :string, :length => 5
  end

  def test_space_string
    buf = "Name      Last "
    ss = BBSpaceString.new(buf)
    assert(ss)
    assert_equal("Name", ss.name)
  end  
  
  class BBSubClass < BBSpaceString
  end
  
  def test_subclass
    buf = "Name      Last "
    ss = BBSubClass.new(buf)
    assert(ss)
    #assert_equal("Name", ss.name)
  end  
  
  class BBTimeHHMM < BinaryBlocker::Blocker
    has_one :now, :time_hhmm
  end

  def test_packed_datetime_hhmm
    now = Time.local(1985, 5, 30, 7, 6, 5)
    b = BBTimeHHMM.new
    b.now = now

    buf = b.block
    assert_equal(12 / 2, buf.size)

    b2 = BBTimeHHMM.new(buf)
    assert_not_equal(now, b2.now)

    now = Time.local(1985, 5, 30, 7, 6, 0)
    assert_equal(now, b2.now)
  end

  def test_clone
    bb = BBTest1.new
    bb.foo = 32
    bb.bar = 24
    
    assert_equal(32, bb.foo)
    assert_equal(24, bb.bar)
    
    b2 = bb.clone
    assert_equal(32, b2.foo)
    assert_equal(24, b2.bar)
    
    b2.foo = 42
    assert_equal(42, b2.foo)
    assert_equal(32, bb.foo)
  end

  def test_clone_some_more
    bb = BBList.new
    bb.header = 13
    bb.footer = 42
    
    ia = ItemA.new
    ib = ItemB.new
    ib.name = 'widget B'
    bb.items << ia << ib

    b2 = bb.clone
    assert_equal(13, b2.header)
    b2.header = 21
    assert_equal(21, b2.header)
    assert_equal(13, bb.header)    
  end

  class Nested < BinaryBlocker::Blocker
    has_one :name, :string, :length => 20
  end

  class Parent < BinaryBlocker::Blocker
    has_one :rtype, :string, :length => 10
    has_one :nest, Nested
    has_one :footer, :string, :length => 10
  end

  def test_clone_has_one
    p = Parent.new
    p.rtype = 'foo'
    p.nest.name = 'bar'
    p.footer = 'end'

    assert_equal('foo', p.rtype)
    assert_equal('bar', p.nest.name)
    assert_equal('end', p.footer)

    p2 = p.clone
    assert_equal('foo', p2.rtype)
    assert_equal('bar', p2.nest.name)
    assert_equal('end', p2.footer)

  end
end
