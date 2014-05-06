# Super Entity Game Server
# http://segs.nemerle.eu/
# Copyright (c) 2014 Super Entity Game Server Team (see Authors.txt)
# This software is licensed! (See LICENSE for details)

class Log
  def self.write(log_file, text)
    begin
      if Dir["logs"].empty? # this actually returns an array, so we check for emptiness and not nil/true/false
        Dir.mkdir("logs")
      end
      log_file = File.open("logs/#{log_file}", 'a')
      log_file.puts("#{Time.now.asctime} -- #{text}")
      log_file.close()
    rescue
      puts("Unable to write log file!")
    end
  end
end
