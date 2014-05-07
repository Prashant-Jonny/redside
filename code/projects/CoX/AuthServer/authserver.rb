# Super Entity Game Server
# http://segs.nemerle.eu/
# Copyright (c) 2014 Super Entity Game Server Team (see Authors.txt)
# This software is licensed! (See LICENSE for details)

if RUBY_VERSION < "1.9"
  puts "SEGS/RedSide requires Ruby >=1.9!"
  exit!
end

# Load library path
$LOAD_PATH << "../../../lib"

require 'config'
require 'log'
require 'segs'

puts "#{SEGS::VERSION}"
puts "#{SEGS::RELEASE}"
puts "#{SEGS::URL}\n\n"
puts "Starting AuthServer..."
Log.write "authserver.log", "Starting AuthServer..."
