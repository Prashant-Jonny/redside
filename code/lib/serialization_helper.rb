require 'stringio'
class StringIO
  def readInt16()
    res1 = read(2);
    res1.unpack("S")[0]
  end
  def readInt8()
    res1 = read(1);
    res1.unpack("C")[0]
  end
  def readInt32()
    res1 = read(4);
    res1.unpack("L")[0]
  end
  def readSInt32()
    res1 = read(4);
    res1.unpack("l")[0]
  end
  def readFloat()
    res1 = read(4);
    res1.unpack("F")[0]
  end
  def readCstring
    res=""
    while((c=self.getc)!=0)
      res+=c.chr
    end
    res
  end
end