require_relative 'growingbuffer'
class BitStream < GrowingBuffer
  BITS_PER_BYTE = 8
  BITS_PER_DWORD = 32
  attr_reader :m_byteAligned, :m_read_bit_off, :m_write_bit_off

  def initialize(src=nil)
    reset()
    super(src)
    @m_byte_aligned = false
  end

  def store_bits(num_bits, data_bits) 
    raise RuntimeError.new if (num_bits > BITS_PER_DWORD)

    if(num_bits>get_writable_bits())
      new_size = @m_size+(num_bits>>3)
      # growing to accommodate !
      if(resize(new_size+7)==-1)
        @m_last_err = 1;
        return
      end
    end
    #  If this stream is byte-aligned, then we'll need to use a byte-aligned
    #  value for nBits
    if(is_byte_aligned)
        if(num_bits) # mask out non-needed
            data_bits &= (1<<num_bits)-1
        end
        num_bits = BYTE_ALIGN(num_bits)
    end
    uStoreBits(num_bits,data_bits)
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
  # packed bits handle any value, nBits is just a hint 
  # as to how many bits the encoding of dataBits needs
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

  def get_packed_bits(min_bits)
    if is_byte_aligned()
      return get_bits(32)
    end

    accumulator = 0
    while get_readable_bits() > 0 do
      bits = get_bits(min_bits)
      bit_mask = BIT_MASK(min_bits)

      if bits < bit_mask || min_bits == BITS_PER_DWORD
        return bits + accumulator
      end

      min_bits *= 2
      accumulator += bit_mask

      if min_bits > BITS_PER_DWORD
        min_bits = BITS_PER_DWORD
      end
    end

    return -1
  end

  def get_packed_bits_with_debug_info(min_bits)
    if get_bits(3) != BS_PACKEDBITS
      return 0
    end
    get_packed_bits(5)
    return get_packed_bits(min_bits)
  end

  # Retrieves a client-specified "array" of bits.  The main difference between 
  # this function and get_bits() is that this one can potentially retrieve more
  # than 32 bits.
  def get_bit_array(target, nbits)
    byte_align(true, false)
    nbytes(nbits >> 3)
    get_bytes(target, nbytes)
  end

  # Retrieves a client-specified "array" of bits.  The main difference between
  # this function and get_bits() is that this one can potentially retrieve more
  # than 32 bits.
  def get_bit_array_with_debug_info(array, nbytes)
    if get_bits(3) != BS_BITARRAY
      return
    end
    get_packed_bits(5)
    get_bit_array(array, nbytes)
  end

  # Retrieves a null-terminated C-style string from the bit stream
  def get_string(str)
    if get_readable_bits() < 8
      @m_last_err = 1
      return
    end

    str = ""
    bits_left = BITS_LEFT(m_read_bit_off)
    chr = nil

    begin
      chr = @m_buf[@m_read_off] >> @m_read_bit_off # will need to look at this line and the one below since ruby
      chr |= @m_buf[++@m_read_off] << bitsLeft    # lacks support for the prefix operator and verify syntax of []

      if chr
        str += chr
      end

      if chr != '\0' && get_readable_bits() < 8
        @m_last_err = 1
        return
      end
    end while chr != '\0'
  end

  # Retrieves a null-terminated C-style string from the bit stream
  def get_string_with_debug_info(str)
    if get_bits(3) != BS_STRING
      return
    end
    get_packed_bits(5)
    get_string(str)
  end

  def get_float()
    res = 0.0
    if is_byte_aligned()
      get(res)
    else
      to_convert = get_bits(32)
      res = to_convert.to_f
    end
    return res
  end

  def get_float_with_debug_info()
    if get_bits(3) != BS_F32
      return 0
    end
    get_packed_bits(5)
    return get_float()
  end

  def get_64_bits()
    result = 0
    byte_count = get_bits(3)

    if byte_count > 4
      result = get_bits(32)
      byte_count -= 4
      result += 1
    end

    result = get_bits(8 * byte_count)
    return result
  end

  def get_writable_bits()
    return (get_avail_size() << 3) - @m_write_bit_off
  end

  def get_readable_bits()
    return (get_readable_data_size() << 3) + (@m_write_bit_off - @m_read_bit_off)
  end

  def get_avail_size()
    res = (@m_size - @m_write_off) - (@m_write_bit_off != 0)
    return [0, res].max
  end

  def is_byte_aligned()
    return @m_byte_aligned
  end

  def set_read_pos(pos)    
    @m_read_off = pos >> 3
    @m_read_bit_off = (pos & 0x7) & 0xFF
  end

  def get_read_pos()
    return (@m_read_off << 3) + @m_read_bit_off
  end

  def set_write_pos(pos)
    @m_write_off = pos >> 3
    @m_write_bit_off = pos & 0x7
  end

  def use_byte_aligned_mode(toggle)
    @m_byte_aligned = toggle
    if @m_byte_aligned
      byte_align()
    end
  end

  def byte_align(read_part = true, write_part = true)
    # If bit_pos is 0, we're already aligned
    if write_part
      @m_write_off += (@m_write_bit_off > 0)
      @m_write_bit_off = 0
    end

    if read_part
      @m_read_off += (@m_read_bit_off > 0)
      @m_read_bit_off = 0
    end
  end

  def reset()
    super
    @m_write_bit_off = @m_read_bit_off = 0
  end

  def get_packed_bits_length(nbits, data_bits)
    if is_byte_aligned()
      return get_bits_length(32, data_bits)
    end

    len = 0
    while nbits < 32 && data_bits >= BIT_MASK(nbits) do
      data_bits -= BIT_MASK(nbits)
      len += get_bits_length(nbits, BIT_MASK(nbits))
      nbits *= 2
      if nbits > 32
        nbits = 32
      end
    end

    len += get_bits_length(nbits, data_bits)
    return len
  end

  def get_bits_length(nbits, data_bits)
=begin
    UNUSED METHOD
    # If this stream is byte aligned, then we'll need to use a byte-aligned
    # value for nbits
    num_bits = is_byte_aligned() ? byte_align(nbits) : nbits
    raise "numbits is less than #{BITS_PER_DWORD}" unless num_bits <= BITS_PER_DWORD

    bits_added = 0
    bits = 0

    num_bits.each do |nb|
      # If we still have more bits left to copy than are left in
      # this byte, then we only copy the number of bits left in
      # the current byte.
      bits = num_bits >= BITS_LEFT() ? get_bits_left_in_byte() | num_bits
      bits_added += bits
      num_bits -= bits
    end

    return bits_added
=end
  end

  def set_byte_length(byte_len)
    raise NotImplementedError.new()
  end

  def compress_and_store_string(str)
    decomp_len = str.length + 1
    len = (decomp_len * 1.0125) + 12
    buf = Array.new(len)
    compress2(buf, len, str, decomp_len, 5)
    store_packed_bits(1, len)               # store compressed len
    store_packed_bits(1, decomp_len)        # store decompressed len
    store_bit_array(buf, len << 3)          # store compressed string
  end

  def get_and_decompress_string(target)
    decomp_len = 0
    len = 0
    len = get_packed_bits(1)                # store compressed len
    decomp_len = get_packed_bits(1)         # decompressed len
    dst = Array.new(decompLen)
    src = Array.new(len)
    get_bit_array(src, len << 3)
    uncompress(dst, decomp_len, src, len)
    target.assign(dst, decomp_len)
  end
end
