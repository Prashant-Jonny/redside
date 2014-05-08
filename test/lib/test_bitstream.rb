# File:  tc_simple_number.rb
 
require "bitstream"
require "test/unit"
require 'stringio'
class TestBitStream < Test::Unit::TestCase
  def test_initial_state
    bs = BitStream.new("")
    assert_equal(bs.get_readable_bits(), 0)
    assert_equal(bs.is_byte_aligned, false)
    bs = BitStream.new("11")
    assert_equal(bs.get_readable_bits(), 16)
  end

  def test_byte_alignment
    bs = BitStream.new("")
    bs.store_bits(3, 3)
    bs.byte_align(true, true)             # after aligning to next bytes we should have 8 bits readable
    assert_equal(bs.get_readable_bits, 8)
    assert_equal(bs.get_bits(3), 3)
    assert_equal(bs.get_bits(5), 0)       # the rest of auto-added bits should be zeroes
  end

  def test_plain_bits
    bs = BitStream.new("")
    bs.store_bits(2, 1)
    assert_equal(bs.get_bits(2), 1)
  end

  def test_packed_bits
    bs = BitStream.new("")    
    bs.store_packed_bits(3, 11)
    assert_equal(bs.get_packed_bits(3), 11)
  end
  def test_string
    bs = BitStream.new("")    
    bs.store_string("Strings of Destiny!")
    assert_equal(bs.get_string(), "Strings of Destiny!")
  end
  def test_mixed_stores
    bs = BitStream.new("")
    bs.store_packed_bits(3, 5)
    bs.store_bits(3, 4)
    bs.store_string("Test me baby one more time")
    payload = [87].pack("c*")
    bs.store_bit_array(payload, payload.size*8)
    assert_equal(bs.get_packed_bits(3), 5)
    assert_equal(bs.get_bits(3), 4)
    assert_equal(bs.get_string(), "Test me baby one more time")
    assert_equal(bs.get_bit_array(payload.size*8),payload)
  end
end
