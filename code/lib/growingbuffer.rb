require 'stringio'
require 'serialization_helper'
class GrowingBuffer
  # if GrowingBuffer is passed String, it will use that instance
  def initialize(dat=nil)
    # 
    if(dat.is_a?(String))
      @m_buf = dat
    else
      @m_buf = String.new(dat.to_s)
    end
    @m_buf.force_encoding('ASCII-8BIT')
    @m_read_off = 0
    @m_write_off = 0
    @m_write_off = dat.size() if( not dat.nil?)
    @m_size = @m_write_off
  end
  def get_readable_data_size
    @m_write_off - @m_read_off
  end
  def reset
    @m_write_off = 0
    @m_read_off = 0
  end
end