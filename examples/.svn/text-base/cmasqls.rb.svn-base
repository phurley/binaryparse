require 'blocker'
require 'stringio'

class CMASqlHeader < BinaryBlocker::Blocker
  has_one :record_type, :uint8, :key => 0
  has_one :register,    :uint32
  has_one :transno,     :uint32
  has_one :trandate,    :string, :length => 8
  has_one :trantime,    :string, :length => 4
  has_one :datasource,  :string, :length => 64
end

class CMASqlStmt < BinaryBlocker::Blocker
  has_one :record_type, :uint8, :key => 1
  has_one :sql_flags,   :uint32
  has_one :sequence,    :uint32
  has_one :stmt,        :string, :length => 80
end

class CMASqlTrailer < BinaryBlocker::Blocker
  has_one :record_type, :uint8, :key => 99
  has_one :register,    :uint32
  has_one :transno,     :uint32
  has_one :delim,       :string, :length => 3, :key => "\xde\r\n"
end

class CMASQLRec < BinaryBlocker::Blocker
  has_one :header, CMASqlHeader
  has_list_of :items, [CMASqlStmt]
  has_one :footer, CMASqlTrailer
  
  StatementStruct = Struct.new(:sql, :flags)
  def statements
    stmts = []
    stmt = StatementStruct.new("")
    items.each do |item|
      stmt.flags = item.sql_flags unless stmt.flags
      stmt.sql += item.stmt
      
      if item.sequence == 0
        stmts << stmt
        stmt = StatementStruct.new("")
      end
    end
    stmts
  end
    
  def inspect
    result = StringIO.new
    result.puts "Header: #{header.datasource}"
    statements.each do |item|
      result.puts "Stmt (#{item.flags}): #{item.sql}"
    end
    result.puts "Trailer: #{footer.record_type}"
    result.string
  end  
end

# Note using binary blocker to parse out "junk" is pretty expensive, but 
# then again you only pay the time when there is an error, so it might not
# be a bad idea
class CMASQLJunk < BinaryBlocker::Blocker
  has_one :junk, :int8
end

class CMASQLSmartRec < BinaryBlocker::Blocker
  has_one_of :rec, [CMASQLRec, CMASqlTrailer, CMASQLJunk]
end

def read_trans(io)
  CMASQLRec.new(io)
end

File.open("cmasqls.dat", "rb") do |sqldat|
  until sqldat.eof?
    start = sqldat.pos
    rec = CMASQLSmartRec.new(sqldat)
    next if CMASQLJunk === rec.rec
    puts "#{rec.rec.class}: #{start}-#{sqldat.pos}"  
    p rec.rec
  end
end