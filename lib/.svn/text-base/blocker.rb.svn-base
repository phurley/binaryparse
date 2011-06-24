# The purpose of BinaryBlocker is to parse semi-complicated binary files. It 
# can handle all the various data types supported by Array#pack and 
# String#unpack, but the real benefit is with more complicated layouts, that
# might include files with headers and a variable number of body records 
# followed by a footer. It also supports, packed numeric 
# (BinaryBlocker::PackedNumberEncoder) and date fields 
# (BinaryBlocker::PackedDateEncoder) 

begin
  require 'uconv'
rescue LoadError
end

require 'date'
require 'time'

module BinaryBlocker
  class << self
    def klasses
      @klasses ||= {}
    end
   
    def pretty_print(obj)
      obj.text "FOO"
      #obj.text self.class.pretty_print
    end

    # To simplify naming of classes and laying out fields in your structures
    # they can be registered:
    #
    # BinaryBlocker.register_klass(:string, FixedStringEncoder)
    def register_klass(sym, klass)
      @klasses ||= {}
      @klasses[sym] = klass
    end
    
    # Handy helper method that returns the size of a given pack/unpack format
    # string
    def sizeof_format(format)
      length = 0
      format.scan(/(\S_?)\s*(\d*)/).each do |directive,count|
        count = count.to_i
        count = 1 if count == 0
        
        length += case directive
        when 'A', 'a', 'C', 'c', 'Z', 'x' ; count
        when 'B', 'b' ; (count / 8.0).ceil
        when 'D', 'd', 'E', 'G' ; count * 8
        when 'e', 'F', 'f', 'g' ; count * 4
        when 'H', 'h' ; (count / 2.0).ceil
        when 'I', 'i', 'L', 'l', 'N', 'V' ; count * 4
        when 'n', 'S', 's', 'v' ; count * 2
        when 'Q', 'q' ; count * 8
        when 'X' ; count * -1
        else raise ArgumentError.new("#{directive} is not supported in sizeof_format")
        end
      end
      
      length
    end
    
    def pack_symbols
      { 
        :int8   => 'c', 
        :uint8  => 'C',
        :int16  => 's',
        :uint16 => 'S',
        :int32  => 'i',   
        :uint32 => 'I',
        :int64  => 'q',    
        :uint64 => 'Q'
      }
    end
    
    # As we have to process some fields to determine what type they are
    # (that is we sometimes start and half to backup), this routine takes
    # any io (that can be repositioned) and yields to a block -- if the 
    # block returns not _true_ it will reset the original position of the 
    # io stream. If you need to use BinaryBlocker with a non-repositioning
    # stream (like a TCP/IP stream), see the handy BufferedIO class.
    def with_guarded_io_pos(io)
      pos = io.pos
      status = yield io
    ensure
      io.pos = pos unless status
    end
    
  end
  
  # This is the base class for all the various encoders. It supports a variety
  # of options (as Symbols in a Hash):
  #
  # default::       used as the default value for the element
  # pre_block::     passed the value before being blocked
  # post_block::    passed the blocked value before returned
  # pre_deblock::   passed the io before attempting to deblock it (hard to imagine
  #                 why you would need this but I was compelled by orthaganality)
  # post_deblock::  passed the deblocked value before being stored internally
  # get_filter::    more info
  # set_filter::    all done
  #
  # It also supports either a string or io parameter which will be used to 
  # initialize the class
  class Encoder
 
    def me
      self.class.superclass.to_s
    end

    # Parameters: (io | buf, options_hash)
    #
    # Options (lambda):
    #
    # default::       used as the default value for the element
    # pre_block::     passed the value before being blocked
    # post_block::    passed the blocked value before returned
    # pre_deblock::   passed the io before attempting to deblock it (hard to imagine
    #                 why you would need this but I was compelled by orthaganality)
    # post_deblock::  passed the deblocked value before being stored internally
    # get_filter::    more info
    # set_filter::    all done
    #   
    def initialize(*opts)
      initialize_options(*opts)
      initialize_data(*opts)
    end
    
    # 
    def block(io=nil)
      val = if @pre_block
        @pre_block.call(self.value)
      else
        self.value
      end
      result = internal_block(val)
      if @post_block
        result = @post_block.call(result)
      end
      io.write(result) if io
      result
    end
    
    # This routine takes an io and will parse the stream 
    # on success it returns the object, on failure it 
    # returns a nil
    def deblock(io)
      with_guarded_io_pos(io) do
        if @pre_deblock
          # does this serve any real purpose? other
          # than making me feel good and orthoginal
          io = @pre_deblock.call(io)
        end
        self.value = internal_deblock(io)
        if @post_deblock
          self.value = @post_deblock.call(self.value)
        end
        self.value || self.valid?
      end
    end
    
    def key_value?
      @opts[:key]
    end
    
    protected
    
    # Override valid? to allow check constraints on a particular 
    # record type, on failure 
    def valid?
      true
    end
    
    def value
      v = @value
      if @get_filter
        @get_filter.call(v) 
      else
        v
      end
    end
    
    def value=(val)
      val = @set_filter.call(val) if @set_filter
      @value = val
    end
    
    def initialize_options(*opts)
      @opts ||= {}
      opts = opts.find { |o| o.respond_to? :to_hash }
      if opts
        @opts = @opts.merge(opts)
        @value = @opts[:default] || @opts[:key] || @value
        @pre_block = @opts[:pre_block]
        @pre_deblock = @opts[:pre_deblock]
        
        @get_filter = @opts[:get_filter]
        @set_filter = @opts[:set_filter]
        
        @post_block = @opts[:post_block]
        @post_deblock = @opts[:post_deblock]
      end
    end
    
    def initialize_data(*opts)
      data = opts.find { |o| !o.respond_to? :to_hash }
      if data.respond_to? :to_str
        raise "Unable to parse block" unless deblock(StringIO.new(data))
      elsif data.respond_to? :read
        raise "Unable to parse block" unless deblock(data)
      end
    end
    
    def with_guarded_io_pos(io)
      result = nil
      BinaryBlocker.with_guarded_io_pos(io) do
        result = yield io
        valid?
      end && result
    end
    
    def internal_block(value) 
      value
    end
    
    def internal_deblock(io)
      ''
    end    
  end
  
  # All Encoders that store multiple items subclass from 
  # here. 
  class GroupEncoder < Encoder
    class << self
      def attributes
        @attributes
      end
      
      def attributes=(a)
        @attributes=a
      end
      
      def lookup
        @lookup
      end
      
      def keys
        @lookup.keys.sort_by { |k| @lookup[k] }
      end
      
      def lookup=(l)
        @lookup=l
      end
      
      def klasses
        @klasses
      end
      
      def klasses=(k)
        @klasses = k
      end
      
      def inherited(obj)
        obj.instance_eval do
          self.klasses = self.klasses || BinaryBlocker.klasses.clone
          self.attributes = self.attributes || []
          self.lookup = self.lookup || {}
        end
        super
      end
      
      # One and only one (this is the easiest :-)
      def has_one(sym, klass, *opts) 
        klass = self.klasses[klass] if self.klasses[klass]
        self.lookup[sym] = self.attributes.size
        self.attributes << lambda { klass.new(*opts) }
      end
      
      def include_klasses(klasses, *opts)
        klasses = klasses.map do |k| 
          case
          when @klasses[k]          ; lambda { @klasses[k].new(*opts) }
          when k.respond_to?(:call) ; k
          when k.respond_to?(:new)  ; lambda { k.new(*opts) }
          else raise "Unable to process class: #{k}"
          end
        end
      end
      
      def has_one_of(sym, klasses, *opts)
        klasses = include_klasses(klasses, *opts) 
        self.lookup[sym] = self.attributes.size 
        self.attributes << lambda { OneOfEncoder.new(klasses, *opts) }
      end
      
      def has_counted_array(sym, count_type, klasses, *opts)
        klasses = include_klasses(klasses, *opts)
        self.lookup[sym] = self.attributes.size 
        self.attributes << lambda { CountedArrayEncoder.new(count_type, klasses, *opts) }
      end
      
      def has_fixed_array(sym, count, klasses, *opts)
        klasses = include_klasses(klasses, *opts)
        self.lookup[sym] = self.attributes.size 
        self.attributes << lambda { FixedArrayEncoder.new(count, klasses, *opts) }
      end
      
      def has_bit_field(sym, type, bit_info, *opts)
        self.lookup[sym] = self.attributes.size
        self.attributes << lambda { BitFieldEncoder.new(type, bit_info, *opts) }
      end
      
      def has_list_of(sym, klasses, *opts)
        klasses = include_klasses(klasses, *opts)
        self.lookup[sym] = self.attributes.size 
        self.attributes << lambda { ListOfEncoder.new(klasses, *opts) }
      end
      
      def register_klass(sym, klass)
        @klasses ||= {}
        @klasses[sym] = klass
      end
      
      def clear_registered_klasses
        @klasses = {}
      end
    end
    
    def initialize(*opts)
      @lookup = self.class.lookup.clone
      @value = self.class.attributes.map { |a| a.call }
      super

      opts.each do |o|
        if o.respond_to? :to_hash
          o.keys.each do |key|
            if pos = @lookup[key.to_sym]
              unless @value[pos].respond_to?(:key_value?) && @value[pos].key_value?
                @value[pos].value = o[key]
              end
            end
          end
        end
      end                
    end 
   
    alias :orig_clone :clone
    def clone
      new_me = orig_clone
      new_val = self.class.attributes.map { |a| a.call }
      new_val.each_with_index do |v,i|
        v.value = @value[i].value
      end
      new_me.instance_eval do
        @value = new_val
      end
      new_me
    end
    
    def block
      @value.inject("") do |a,b|
        a + b.block 
      end
    end
    
    def deblock(io)
      BinaryBlocker.with_guarded_io_pos(io) do
        @value.all? { |o| o.deblock(io) }
      end
    end    

    def to_h
      result = {}
      @lookup.each_pair do |key, index|
        value = @value[index].value
        value = value.to_h if value.respond_to? :to_h
        result[key] = value
      end    
      result
    end
          
    def method_missing(sym, *args)
      super unless @lookup
      if pos = @lookup[sym]
        return @value[pos].value
      else
        sym = sym.to_s
        if sym[-1] == ?=
          if pos = @lookup[sym[0..-2].to_sym]
            raise NoMethodError.new("undefined method `#{sym}''") if @value[pos].key_value?
            return @value[pos].value = args.first
          end
        end
      end
      puts "method missing #{sym.inspect} #{bt}"
      super
    end
    
    def value
      self
    end
    
    def value=(val)
      @lookup.keys.each do |key|
        @value[@lookup[key]].value = val.send(key)
      end
    end    
    
    def valid?
      @value.all? { |a| a.valid? }
    end
  end  
  
  class SimpleEncoder < Encoder
  
    def self.register(sym, fmt, *opts)
      klass = Class.new(SimpleEncoder)
      klass.send(:define_method,:initialize) do |*opts|
        initialize_options(*opts)
        
        @format = fmt
        @length = BinaryBlocker.sizeof_format(@format)
        
        @key = @opts[:key]
        @valid = @opts[:valid]
        
        initialize_data(*opts)
      end
      BinaryBlocker.register_klass(sym, klass)
    end
   
    def internal_block(val)
      if val.nil?
        [0].pack(@format)
      else
        [val].pack(@format)
      end
    end
    
    def internal_deblock(io)
      buffer = io.read(@length)
      result = buffer.unpack(@format)
      result.first
    end
    
    def valid?
      if @valid
        @valid.call(self.value)
      else
        self.value != nil && (@key == nil || @key === self.value)
      end
    end
   
    def inspect
      "#{@format} - #{@length} - #{self.value.inspect}"
    end
  end
  
  SimpleEncoder.register( :int8, 'c')
  SimpleEncoder.register(:uint8, 'C')
  SimpleEncoder.register( :int16, 's')
  SimpleEncoder.register(:uint16, 'S')
  SimpleEncoder.register( :int32, 'i')    
  SimpleEncoder.register(:uint32, 'I')
  SimpleEncoder.register( :int64, 'q')    
  SimpleEncoder.register(:uint64, 'Q')
  
  class FixedStringEncoder < SimpleEncoder
    def initialize(*opts)
      @value = ''
      initialize_options(*opts)
      
      @length = @opts[:length].to_i
      raise ArgumentError.new("Missing or invalid string length") unless @length > 0
      @format = "Z#{@length}"
      
      @key = @opts[:key]
      @valid = @opts[:valid]
      
      initialize_data(*opts)
    end
    
  end
  BinaryBlocker.register_klass(:string, FixedStringEncoder)
 
  class ByteStringEncoder < FixedStringEncoder
	  def initialize(*opts)
		  super
		  @format = "a#{@length}"
		end
	end
  BinaryBlocker.register_klass(:bytes, ByteStringEncoder)

  class SpacedStringEncoder < SimpleEncoder
    def initialize(*opts)
      @value = ''
      initialize_options(*opts)
      
      @length = @opts[:length].to_i
      raise ArgumentError.new("Missing or invalid string length") unless @length > 0
      @format = "A#{@length}"
      
      @key = @opts[:key]
      @valid = @opts[:valid]
      
      initialize_data(*opts)
    end
  end
  BinaryBlocker.register_klass(:sstring, SpacedStringEncoder)
  
  class FixedUTF16StringEncoder < SimpleEncoder
    def initialize(*opts)
      initialize_options(*opts)
      
      @length = @opts[:length].to_i
      @length *= 2
      raise ArgumentError.new("Missing or invalid string length") unless @length > 0
      @format = "Z#{@length}"
      
      @key = @opts[:key]
      @valid = @opts[:valid]
      
      initialize_data(*opts)
    end
    
    def internal_block(val)
      [Uconv.u8tou16(val || "")].pack(@format)
    end
    
    def internal_deblock(io)
      buffer = io.read(@length)
      Uconv.u16tou8(buffer).sub(/\000+$/,'')
    end    
  end
  BinaryBlocker.register_klass(:utf16_string, FixedUTF16StringEncoder)
  BinaryBlocker.register_klass(:utf16, FixedUTF16StringEncoder)
  
  class PackedNumberEncoder < SimpleEncoder
    def initialize(*opts)
      initialize_options(*opts)
      
      @length = @opts[:length].to_i
      raise ArgumentError.new("Missing or invalid string length") unless @length > 0
      @length += 1 if @length[0] == 1
      @bytes = @length / 2
      @format = "H#{@length}"
      
      @key = @opts[:key]
      @valid = @opts[:valid]
      
      initialize_data(*opts)
    end
    
    def internal_block(val)
      ["%0#{@length}d" % val.to_i].pack(@format)
    end
    
    def internal_deblock(io)
      buffer = io.read(@bytes)
      result = buffer.unpack(@format)
      result.first.to_i
    end    
  end
  BinaryBlocker.register_klass(:packed, PackedNumberEncoder)
  
  class NewPackedNumberEncoder < SimpleEncoder
    def initialize(*opts)
      initialize_options(*opts)
      
      @length = @opts[:length].to_i
      raise ArgumentError.new("Missing or invalid string length") unless @length > 0
      @length += 1 if @length[0] == 1
      @bytes = @length / 2
      @format = "H#{@length}"
      
      @key = @opts[:key]
      @valid = @opts[:valid]
      
      initialize_data(*opts)
    end
    
    def internal_block(val)
      [val.to_s.rjust(@length,"\xff")].pack(@format)
    end
    
    def internal_deblock(io)
      buffer = io.read(@bytes)
      result = buffer.unpack(@format)
      result.first.match(/(\d+)/)[0].to_i
    end    
  end
  BinaryBlocker.register_klass(:new_packed, NewPackedNumberEncoder)

  class PackedDateEncoder < PackedNumberEncoder
    def initialize_options(*opts)
      super
      @opts[:length] = 8
    end
    
    def internal_block(val)
      if val
        super val.year * 10000 + val.month * 100 + val.mday
      else
        super 0
      end 
    end
    
    def internal_deblock(io)
      buffer = io.read(@bytes)
      result = buffer.unpack(@format)
      year, month, day = result.first.unpack("A4A2A2").map { |v| v.to_i }
      if month.zero?
        nil
      else
        Date.civil(year, month, day)
      end
    end    
    
    def valid?
      case @value
      when Date ; true
      when Time ; true
      when nil  ; true
      else 
        false
      end        
    end
    
  end
  BinaryBlocker.register_klass(:date, PackedDateEncoder)
  
  class PackedDateEncoderMMDDYYYY < PackedNumberEncoder
    def initialize_options(*opts)
      super
      @opts[:length] = 8
    end
    
    def internal_block(val)
      if val
        super val.month * 1000000 + val.mday * 10000 + val.year
      else
        super 0
      end 
    end
    
    def internal_deblock(io)
      buffer = io.read(@bytes)
      result = buffer.unpack(@format)
      month, day, year = result.first.unpack("A2A2A4").map { |v| v.to_i }
      if month.zero?
        nil
      else
        Date.civil(year, month, day)
      end
    end    
    
    def valid?
      case @value
      when Date ; true
      when Time ; true
      when nil  ; true
      else 
        false
      end        
    end
    
  end
  BinaryBlocker.register_klass(:date_MMDDYYYY, PackedDateEncoderMMDDYYYY)
  
  class PackedDateTimeEncoder < PackedNumberEncoder
    def initialize_options(*opts)
      super
      @opts[:length] = 14
    end
    
    def internal_block(val)
      if val
        super sprintf("%04d%02d%02d%02d%02d%02d", val.year, val.month, val.mday, val.hour, val.min, val.sec).to_i
      else
        super 0
      end
    end
    
    def internal_deblock(io)
      buffer = io.read(@bytes)
      result = buffer.unpack(@format)
      year, month, day, hour, min, sec = result.first.unpack("A4A2A2A2A2A2").map { |v| v.to_i }
      if month.zero?
        nil
      else
        Time.local(year, month, day, hour, min, sec)
      end
    end    
    
    def valid?
      case @value
      when Time ; true
      when nil  ; true
      else 
        false
      end        
    end
    
  end
  BinaryBlocker.register_klass(:time, PackedDateTimeEncoder)
  BinaryBlocker.register_klass(:datetime, PackedDateTimeEncoder)
  
  # Seems awfully specific, why is this here? Well my boss was nice
  # enough to open source the code, so I figured something that made
  # our (company) work easier could go in, even if I would have 
  # normally rejected it.
  class PackedDateTimeHHMMEncoder < PackedNumberEncoder
    def initialize_options(*opts)
      super
      @opts[:length] = 12
    end

    def internal_block(val)
      if val
        super sprintf("%04d%02d%02d%02d%02d", val.year, val.month, val.mday, val.hour, val.min).to_i
      else
        super 0
      end
    end

    def internal_deblock(io)
      buffer = io.read(@bytes)
      result = buffer.unpack(@format)
      year, month, day, hour, min = result.first.unpack("A4A2A2A2A2").map { |v| v.to_i }
      if month.zero?
        nil
      else
        Time.local(year, month, day, hour, min, 0)
      end
    end    
    
    def valid?
      case @value
      when Time ; true
      when nil  ; true
      else 
        false
      end        
    end
  end
  BinaryBlocker.register_klass(:time_hhmm, PackedDateTimeHHMMEncoder)
  BinaryBlocker.register_klass(:date_hhmm, PackedDateTimeHHMMEncoder)

  # Seems awfully specific, why is this here? Well my boss was nice
  # enough to open source the code, so I figured something that made
  # our (company) work easier could go in, even if I would have 
  # normally rejected it.
  class PackedDateTimeMMDDYYYYHHMMEncoder < PackedNumberEncoder
    def initialize_options(*opts)
      super
      @opts[:length] = 12
    end

    def internal_block(val)
      if val
        super sprintf("%02d%02d%04d%02d%02d", val.month, val.mday, val.year, val.hour, val.min).to_i
      else
        super 0
      end
    end

    def internal_deblock(io)
      buffer = io.read(@bytes)
      result = buffer.unpack(@format)
      month, day, year, hour, min = result.first.unpack("A2A2A4A2A2").map { |v| v.to_i }
      if month.zero?
        nil
      else
        Time.local(year, month, day, hour, min, 0)
      end
    end    
    
    def valid?
      case @value
      when Time ; true
      when nil  ; true
      else 
        false
      end        
    end
  end
  BinaryBlocker.register_klass(:date_mmddyyyyhhmm, PackedDateTimeMMDDYYYYHHMMEncoder)

  class OneOfEncoder < Encoder
  
    def inspect
      "OneOf #{@classes.join(',')} -> #{@obj.class} -> #{@obj.inspect}" 
    end
    
    def initialize(classes, *opts)
      @classes = classes.map { |o| o.call(*opts) }
      @obj = nil
      super(*opts)
    end
    
    def internal_block(val)
      if val
        val.block
      else
        @classes.first.block
      end
    end
  
    def pretty_print(obj)
      @obj.pretty_print(obj)
    end

    def internal_deblock(io)
      @obj = nil
      with_guarded_io_pos(io) do
        @classes.each do |obj|
          if obj.deblock(io)
            @obj = obj
            break 
          end 
          false
        end
      end       
      @obj
    end
    
    def method_missing(sym, *args)
      if @obj
        @obj.send sym, *args
      else
        super
      end
    end
    
    def valid?
      @obj && @obj.valid?
    end
  end
  
  class FixedArrayEncoder < GroupEncoder
    def initialize(count, classes, *opts)
      initialize_options(*opts)
      @count = count
      @classes = classes
      @value = Array.new(count) { OneOfEncoder.new(classes, *opts) }
      initialize_data(*opts)
    end
    
    def internal_block(val)
      val.inject("") { |r, o| r + o.block }
    end
    
    def deblock(io)
      result = []
      with_guarded_io_pos(io) do
        @count.times do
          result << OneOfEncoder.new(@classes, io, @opts)
        end
        @value = result
      end 
    end
    
    def to_h
      result = []
			@value.each do |value|
        value = value.to_h if value.respond_to? :to_h
				result << value
      end    
      result
    end
        
	  def clone
		  result = orig_clone
		end

		def size
			@count
		end

		def value
			self
		end

		def value=(newval)
			raise RangeError.new("Array size mismatch") unless newval.size == @count
      @count.times do |i|			
				@value[i] = newval[i]
			end
			newval
		end

    def [](offset)
      raise RangeError.new("Access (#{offset}) out of range (#{@count})") unless (0...@count) === offset
      @value[offset]
    end
    
    def []=(offset,val)
      raise RangeError.new("Access (#{offset}) out of range (#{@count})") unless (0...@count) === offset
      @value[offset] = val
    end
  end
  
  class ListOfEncoder < GroupEncoder
    def initialize(classes, *opts)
      initialize_options(*opts)
      @count = 0
      @classes = classes
      @value = []
      initialize_data(*opts)
    end

    def value=(other)
      @value = other.value.clone
    end
        
    def internal_block(val)
      val.inject("") { |r, o| r + o.block }
    end
    
    def deblock(io)
      result = []
      with_guarded_io_pos(io) do
        oe = OneOfEncoder.new(@classes, @opts)
        while oe.deblock(io)
          result << oe
          oe = OneOfEncoder.new(@classes, @opts)
        end
      end 
      @value = result
    end
    
    def [](offset)
      raise RangeError.new("Access (#{offset}) out of range (#{@value.size})") unless (0...@value.size) === offset
      @value[offset]
    end
    
    def []=(offset,val)
      raise RangeError.new("Access (#{offset}) out of range (#{@value.size})") unless (0...@value.size) === offset
      @value[offset] = val
    end
    
    def each
      @value.each { |v| yield v }
    end
    
    def <<(val)
      @value << val
    end    
    
    def size
      @value.size
    end
    alias length size
  end
  
  class CountedArrayEncoder < GroupEncoder
    def initialize(count_type, classes, *opts)
      # this is dynamic now, but we init to zero for the range checking
      @count_enc = BinaryBlocker.pack_symbols[count_type] || count_type
      @count = 0 
      initialize_options(*opts)
      @classes = classes
      @value = []
      initialize_data(*opts)
    end
    
    def internal_block(val)
      buf = [val.size].pack(@count_enc)
      val.inject(buf) { |r, o| r + o.block }
    end
    
    def deblock(io)
      length = BinaryBlocker.sizeof_format(@count_enc)
      result = []
      with_guarded_io_pos(io) do
        @count = io.read(length).unpack(@count_enc)
        @count.times do
          result << OneOfEncoder.new(@classes, io, @opts)
        end
      end 
      @value = result
    end
    
    def [](offset)
      raise RangeError.new("Access (#{offset}) out of range (#{@count})") unless (0...@count) === offset
      @value[offset]
    end
    
    def []=(offset,val)
      raise RangeError.new("Access (#{offset}) out of range (#{@count})") unless (0...@count) === offset
      @value[offset] = val
    end
    
    def <<(val)
      @count += 1
      @value << val
    end
    
    def size
      @count
    end
    alias length size
  end
  
  class BitFieldEncoder < Encoder
    def initialize(type, bit_info, *opts)
      @type = BinaryBlocker.pack_symbols[type] || type
      @length = BinaryBlocker.sizeof_format(@type)
      @bit_info = {}
      pos = 0
      bit_info.each do |bi|
        case bi
        when Symbol
          @bit_info[bi.to_sym] = [pos,1]
          pos += 1
          
        when Fixnum
          pos += bi
          
        when Array
          @bit_info[bi.first.to_sym] = [pos, bi.last.to_i]
          pos += bi.last.to_i
        end
      end
      @value = 0
      initialize_options(*opts)
      initialize_data(*opts)
    end
    
    def internal_block(val)
      [val.raw_value || 0].pack(@type)
    end
    
    def internal_deblock(io)
      buffer = io.read(@length)
      result = buffer.unpack(@type)
      result.first
    end
    
    def value
      self
    end
    
    def raw_value
      @value
    end
    
    def method_missing(sym, *args)
      if (bi = @bit_info[sym])
        v = @value >> bi.first
        mask = (1 << bi.last) - 1
        v = v & mask
      else
        sym = sym.to_s
        if sym[-1] == ?=
          if bi = @bit_info[sym[0..-2].to_sym]
            @value &= ~(((1 << bi.last) - 1) << bi.first)
            @value |= args.first.to_i << bi.first 
            return @value
          end
        end
        raise NoMethodError.new("undefined method `#{sym}''")
        # I was using super, but it was throwing a different error
        # which seemed wrong, not sure why
      end
    end
    
  end
  
  class Blocker < GroupEncoder
    def inspect
      result = []
      @lookup.keys.sort_by {|k| @lookup[k]}.each do |k|
        result << [k, @value[@lookup[k]]]
      end
      "#{self.class}: #{result.inspect}"
    end        

    def pretty_print(obj)
      result = []
      @lookup.keys.sort_by {|k| @lookup[k]}.each do |k|
        result << [k, @value[@lookup[k]]]
      end
      obj.text self.class.to_s
      obj.text ": "
      result.pretty_print(obj)
    end

  end
  
end
