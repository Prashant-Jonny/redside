# Super Entity Game Server
# http://segs.nemerle.eu/
# Copyright (c) 2014 Super Entity Game Server Team (see Authors.txt)
# This software is licensed! (See LICENSE for details)

require_relative 'growingbuffer'

class BitStream < GrowingBuffer
  BITS_PER_BYTE = 8
  BITS_PER_DWORD = 32
  attr_reader :m_byte_aligned, :m_read_bit_off, :m_write_bit_off

  def initialize(src = nil)
    reset()
    super(src)
    @m_byte_aligned = false
  end

  def max_value_that_can_be_stored(x)
    (1 << x) - 1
  end

  def n_ones(n)
    (1 << n) - 1
  end

  # Stores a client-specified number of bits into the bit-stream buffer.
  # The bits to store come from the data_bits argument, starting from the
  # least significant bit to the most significant bit.
  def store_bits(num_bits, data_bits)
    raise RuntimeError.new if (num_bits > BITS_PER_DWORD)
    if num_bits > get_writable_bits()
      new_size = @m_size + (num_bits >> 3)
      # growing to accommodate!
      if resize(new_size + 7) == -1
        @m_last_err = 1
        return
      end
    end

    #  If this stream is byte aligned, then we will need to use a byte-aligned
    #  value for nbits.
    if is_byte_aligned()
      if num_bits # mask out non-needed
        data_bits &= (1 << num_bits) - 1
      end
      num_bits = BYTE_ALIGN(num_bits)
    end
    u_store_bits(num_bits, data_bits)
  end
private
  def read_8bytes_at_point(pt)
    raise RuntimeError.new(Out of bounds read) if pt+7 > @m_size
    @m_buf[pt..pt+7].unpack("Q")[0]
  end
  def set_8bytes_at_write_point(val)
    raise RuntimeError.new(Out of bounds read) if @m_write_off+7 > @m_size
    @m_buf[@m_write_off..@m_write_off+7] = [val.to_i].pack("Q")
  end
  def BIT_MASK(x)
    (((1 << (x)) - 1))&0xFFFFFFFF
  end
public
  def u_store_bits(nbits, data_bits)
    tp = nil
    r = nil
    raise "nbits is > 32!" unless nbits <= 32
    raise "m_write_off + 7 is > (m_size + m_safe_area)!" unless @m_write_off + 7 < (@m_size + @m_safe_area)
    tp = read_8bytes_at_point(@m_write_off)
    r = data_bits
    mask_ = BIT_MASK(nbits) << @m_write_bit_off  # all bits in the mask are those that will change
    set_8bytes_at_write_point((r << @m_write_bit_off) | (tp & ~mask_) )# put those bits in
    write_ptr((@m_write_bit_off + nbits) >> 3)   # advance
    @m_write_bit_off = (@m_write_bit_off + nbits) & 0x7
  end

  # Stores a client-specified number of bits into the bit-stream buffer.
  # The bits to store come from the data_bits argument, starting from the
  # least significant bit to the most significant bit.
  def store_bits_with_debug_info(nbits, data_bits)
    store_bits(3, BS_BITS)
    store_packed_bits(5, nbits)
    store_bits(data_bits, nbits)
  end

  def store_float(val)
    if is_byte_aligned()
      put(val)
    else
      store_bits(32, val)
    end
  end

  def store_float_with_debug_info(val)
    store_bits(3, BS_F32)
    store_bits(5, 32)
    store_bits(32, val)
  end

  # Packed bits handle any value. nbits is just a hint 
  # as to how many bits the encoding of data_bits needs.
  def store_packed_bits(nbits, data_bits)
    if is_byte_aligned()
      return store_bits(32, data_bits)
    end

    while (nbits < 32) && (data_bits >= max_value_that_can_be_stored(nbits))
      data_bits -= max_value_that_can_be_stored(nbits)
      store_bits(nbits, n_ones(nbits))
      nbits = [nbits * 2, BITS_PER_DWORD].min
    end

    store_bits(nbits, data_bits)
  end

  # Stores bits in a special "packed" format.
  # ToDo: Develop a better understanding of this method.
  def store_packed_bits_with_debug_info(nbits, data_bits)
    store_bits(3, BS_PACKEDBITS)
    store_packed_bits(5, nbits)
    store_packed_bits(nbits, data_bits)
  end

  # Stores an array of bits in the bit stream buffer. The
  # main difference between store_bit_array and store_bits
  # is that store_bit_array can accept more than 32 bits at a time.
  def store_bit_array(array, nbits)
    nbytes = BITS_TO_BYTES(nbits)
    raise "src is undefined!" unless src
    byte_align()
    put_bytes(src, nbytes)
    @m_buf[@m_write_off] = 0

    if nbits & 7 # unaligned !
      @m_write_off -= 1
      @m_write_bit_off = nbits & 7
    end
  end

  # Stores an array of bits in the bit stream buffer. The
  # main difference between store_bit_array and store_bits
  # is that store_bit_array can accept more than 32 bits at a time.
  def store_bit_array_with_debug_info(array, nbits)
    store_bits(3, BS_BITARRAY)
    store_packed_bits(5, nbits)
    store_bit_array(array, nbits)
  end

  # Stores a NULL-terminated C-style string in the bit stream
  # buffer. It includes the NULL terminator.
  def store_string(str)
    if(!str) # nothing to do ?
      return
    end

    # str.length + 1, because we want to include
    # the NULL byte.
    if is_byte_aligned()
      put_string(str)
      return
    end

    len = str.length + 1
    rshift = 8 - @m_write_bit_off

    if len > get_avail_size()
      if resize(@m_write_off + len) == -1 # space exhausted
        @m_last_err = 1
        return
      end
    end

    idx = 0
    while idx < len do
      upperbits = str[idx] << @m_write_bit_off
      lowerbits = str[idx] >> rshift
      mask = (0xFF >> rshift)
      @m_buf[@m_write_off + idx] = (@m_buf[@m_write_off + idx] & mask) | upperbits
      @m_buf[@m_write_off + idx + 1] = lowerbits
      idx += 1
    end

    @m_write_off += idx
  end

  # Stores a NULL-terminated C-style string in the bit stream
  # buffer. It includes the NULL terminator.      
  def store_string_with_debug_info(str)
    store_bits(3, BS_STRING)
    str_len = 0

    if str
      str_len = str.length
    end

    store_packed_bits(5, str_len)
    store_string(str)
  end

  def get_bits(nbits)
    target = nil

    if nbits > get_readable_bits()
      return false
    end

    if is_byte_aligned()
      nbits = BYTE_ALIGN(nbits)
    end

    target = u_get_bits(nbits)
    return target
  end

  def u_get_bits(nbits)
    r = nil
    tp = nil
    target = nil
    raise "nbits is < 0 or > 32!" unless (nbits > 0) && nbits <= 32
    raise "get_readable_bits() returned < nbits!" unless get_readable_bits() >= nbits
    raise "m_read_off + 7 is > (m_size + m_safe_area)!" unless @m_read_off + 7 < (@m_size + @m_safe_area)
    nbits = ((nbits - 1) &0x1F) + 1 # ensure the nbits range is 1 - 32
    tp = read_8bytes_at_point(@m_read_off)
    r = tp
    r >>= @m_read_bit_off             # starting at the top
    target = r & (~1) >> (64 - nbits)
    read_ptr((@m_read_bit_off + nbits) >> 3)
    @m_read_bit_off = (@m_read_bit_off + nbits) & 0x7
    return target
  end

  def get_bits_with_debug_info(nbits)
    if GetBits(3) != BS_BITS
      return 0
    end
    get_packed_bits(5)
    return get_bits(nbits)
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
    bits_left = BITS_LEFT(@m_read_bit_off)
    chr = nil

    begin
      chr = @m_buf[@m_read_off] >> @m_read_bit_off
      @m_read_off += 1
      chr |= @m_buf[@m_read_off] << bitsLeft

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
    return ((get_avail_size() << 3) - @m_write_bit_off)
  end

  def get_readable_bits()
    return (get_readable_data_size() << 3) + (@m_write_bit_off - @m_read_bit_off)
  end

  def get_avail_size()
    res = (@m_size - @m_write_off)
    res -= 1 if (@m_write_bit_off != 0)
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
      @m_write_off += (@m_write_bit_off > 0) ? 1 : 0
      @m_write_bit_off = 0
    end

    if read_part
      @m_read_off += (@m_read_bit_off > 0) ? 1 : 0
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
    raise "numbits is less than #{BITS_PER_DWORD}!" unless num_bits <= BITS_PER_DWORD

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
