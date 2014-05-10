# Super Entity Game Server
# http://segs.nemerle.eu/
# Copyright (c) 2014 Super Entity Game Server Team (see Authors.txt)
# This software is licensed! (See LICENSE for details)

class Log
  def self.write(severity, log_file, text)
    begin
      if Dir["logs"].empty? # this actually returns an array, so we check for emptiness and not nil/true/false
        Dir.mkdir("logs")
      end
      log_file = File.open("logs/#{log_file}", 'a')

      case severity
        when 0
          log_level = "INFO"
        when 1
          log_level = "WARN"
        when 2
          log_level = "CRIT"
        when 3
          log_level = "DBUG"
        else
          log_level = "DBUG"
      end

      log_file.puts("#{Time.now.asctime} -- #{log_level}: #{text}")
      log_file.close()
    rescue
      puts("Unable to write to #{log_file}!")
    end
  end
end
