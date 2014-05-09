# Super Entity Game Server
# http://segs.nemerle.eu/
# Copyright (c) 2014 Super Entity Game Server Team (see Authors.txt)
# This software is licensed! (See LICENSE for details)

require 'stringio'
require_relative 'serialization_helper'

class GrowingBuffer
  # If GrowingBuffer is passed a String, it will use that instance
  DEFAULT_MAX_SIZE = 0x10000

  def initialize(dat = nil, size = 0)
    if dat.is_a?(String)
      @m_buf = dat
    else
      @m_buf = String.new(dat.to_s)
    end
    @m_buf.force_encoding('ASCII-8BIT')
    @m_read_off = 0
    @m_write_off = 0
    @m_write_off = dat.size() if not dat.nil?
    @m_size = @m_write_off
    @m_safe_area = 0
    @m_max_size = size > DEFAULT_MAX_SIZE ? size : DEFAULT_MAX_SIZE
  end

  def get_readable_data_size
    @m_write_off - @m_read_off
  end

  def reset
    @m_write_off = 0
    @m_read_off = 0
  end

  def resize(accommodate_size)
    new_size = accommodate_size ? 2 * accommodate_size + 1 : 0

    if accommodate_size > @m_max_size
      return -1
    end

    if accommodate_size < @m_size
      return 0
    end

    raise "accommodate_size is > 0x100000!" unless accommodate_size < 0x100000
    new_size = new_size > @m_max_size ? @m_max_size : new_size

    # fix read/write indexers (this will occur only if new_size is less than current size)
    if @m_read_off > new_size
      @m_read_off = new_size
    end

    if @m_write_off > new_size
      @m_write_off = new_size
    end

    if new_size == 0     # requested freeing of internal buffer
      @m_buf = nil       # this allows us to catch calls through unchecked methods quickly
      @m_size = new_size
      return 0
    end

    if new_size > @m_size
      raise "m_write_off is > m_size!" unless @m_write_off <= @m_size # just to be sure

      @m_buf += "\0" * (new_size + @m_safe_area - @m_size)
      @m_size = new_size
    else
      @m_buf = @m_buf.byteslice(new_size)
      @m_size= new_size
    end
    return 0
  end
  def write_ptr(v)
    @m_write_off += v
  end
  def read_ptr(v)
    @m_read_off += v
  end
  def put_bytes(bytes,count)
    
  end
end
