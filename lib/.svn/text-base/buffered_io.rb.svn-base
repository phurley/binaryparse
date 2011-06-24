# Simple class to allow for streamed (i.e. without pos support)
# IO to use the BinaryBlocker utilities, but buffering until flushed
# previously read information.
class BufferedIO
  BLOCK_SIZE = 512
  # Rdoc
  def initialize(io)
    super
    @io = io
    @buffer = ''
    @pos = 0
    @iobase = @io.pos
  end
  
  def flush
    @iobase += @pos
    @buffer = ''
    @pos = 0
    @io.flush
  end
  
  def read(size, buffer = nil)
    if (@buffer.size - @pos) < size
      @buffer += @io.read(BLOCK_SIZE)
    end
    result = @buffer[@pos,size]
    @pos += result.size
    buffer.replace(result) if buffer
    result
  end
  
  def pos
    @iobase + @pos
  end
  
  def pos=(newpos)
    seek(newpos) 
  end
  
  def seek(amount, whence=IO::SEEK_SET)
    case whence
    when IO::SEEK_CUR
      raise "rewind before buffer start" if (amount < @pos)
      @pos -= amount
      @iobase + @pos
      
    when IO::SEEK_END
      raise "Sorry this operation is not supported"
      
    when IO::SEEK_SET
      raise "rewind before buffer start" if (amount < @iobase)
      @pos = amount - @iobase
      @iobase + @pos      
    end
  end
end


