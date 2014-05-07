# File:  tc_simple_number.rb
 
require "bitstream"
require "test/unit"
require 'stringio'
class TestBitStream < Test::Unit::TestCase
 
  def test_initial_state
    bs = BitStream.new("")
    assert_equal(bs.get_readable_bits(), 0 )
    assert_equal(bs.is_byte_aligned,false)
    bs = BitStream.new("11")
    assert_equal(bs.get_readable_bits(), 16 )
  end
  def test_byte_alignment
    bs = BitStream.new("")
    bs.store_bits(3, 3)
    bs.byte_align(true, true) # after aligning to next bytes we should have 8 bits readable
    assert_equal(bs.get_readable_bits,8)
    assert_equal(bs.get_bits(3),3)
    assert_equal(bs.get_bits(5),0) # the rest of auto-added bits should be zeroes
  end
  def test_plain_bits
    bs = BitStream.new("")
    bs.store_bits(2,1)
    assert_equal(bs.get_bits(2), 1 )
  end
  def test_packed_bits
    bs = BitStream.new("")
    
    bs.store_packed_bits(3, 11)
    assert_equal(bs.get_packed_bits(3), 11 )
  end
end
