# Super Entity Game Server
# http://segs.nemerle.eu/
# Copyright (c) 2014 Super Entity Game Server Team (see Authors.txt)
# This software is licensed! (See LICENSE for details)

require 'yaml'

class AbstractOptions
  def parse(options_file)
    raise "I am abstract... Override me!"
  end
end
