class BitStream 
  attr_reader :m_byteAligned,:m_read_bit_off,:m_write_bit_off
  def initialize(stream)    
  end
  def store_bits(nBits, dataBits) 
    raise NotImplementedError.new()
  end
  def u_store_bits(nBits, dataBits)
    raise NotImplementedError.new()
  end
  def store_bits_with_debug_info(nBits, dataBits)
    raise NotImplementedError.new()
  end

  def store_float(val)
    raise NotImplementedError.new()
  end
  def store_float_with_debug_info(val)
    raise NotImplementedError.new()
  end

  def store_packed_bits(nBits, dataBits)
    raise NotImplementedError.new()
  end
  def store_packed_bits_with_debug_info(nBits, dataBits)
    raise NotImplementedError.new()
  end

  def store_bit_array(array,nBits)
    raise NotImplementedError.new()
  end
  def store_bit_array_with_debug_info(array,nBits)
    raise NotImplementedError.new()
  end

  def store_string(str)
    raise NotImplementedError.new()
  end
      
  def store_string_with_debug_info(str)
    raise NotImplementedError.new()
  end

  def get_bits(nBits)
    raise NotImplementedError.new()
  end
  def u_get_bits(nBits)
    raise NotImplementedError.new()
  end
  def get_bits_with_debug_info(nBits)
    raise NotImplementedError.new()
  end

  def get_packed_bits(minbits)
    raise NotImplementedError.new()
  end
  def get_packed_bits_with_debug_info(minbits)
    raise NotImplementedError.new()
  end

  def get_bit_array(array,nBits)
    raise NotImplementedError.new()
  end
  def get_bit_array_with_debug_info(array,nBits)
    raise NotImplementedError.new()
  end

  def get_string()
    raise NotImplementedError.new()
  end
  def get_string_with_debug_info()
    raise NotImplementedError.new()
  end

  def get_float()
    raise NotImplementedError.new()
  end
  def get_float_with_debug_info()
    raise NotImplementedError.new()
  end
  def get_64_bits()
    raise NotImplementedError.new()
  end

  def get_writable_bits()   
    return (getAvailSize()<<3)-m_write_bit_off;
  end
  def  get_readable_bits()   
    return (get_readable_data_size()<<3)+(m_write_bit_off-m_read_bit_off);
  end
  def  get_avail_size()
    
  end
  def is_byte_aligned()
    return @m_byteAligned;
  end

  def set_read_pos(pos)    
    @m_read_off  = pos >> 3;
    @m_read_bit_off  = (pos & 0x7)&0xFF;
  end
  def get_read_pos()  
    return (@m_read_off<<3)  + @m_read_bit_off;
  end
  def set_write_pos( pos) 
    @m_write_off = pos >> 3;
    @m_write_bit_off = pos & 0x7;
  end

  def set_byte_length(length)
    raise NotImplementedError.new()
  end
  def use_byte_aligned_mode(toggle)
    raise NotImplementedError.new()
  end
  def byte_align(read_part=true,write_part=true)
    raise NotImplementedError.new()
  end
  def reset()
    raise NotImplementedError.new()
  end

  def get_packed_bits_length(nBits, dataBits)
    raise NotImplementedError.new()
  end
  def get_bits_length(nBits, dataBits)
    raise NotImplementedError.new()
  end
  def compress_and_store_string(str)
    raise NotImplementedError.new()
  end
  def get_and_decompress_string()
    raise NotImplementedError.new()
  end
end
