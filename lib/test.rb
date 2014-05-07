require_relative 'bitstream'

bs = BitStream.new
bs.put_compressed_string("Testing all the things!")
res = bs.get_compressed_string()
assert_equal(res, "Testing all the things!")
