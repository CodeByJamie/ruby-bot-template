module LogType
    INFO = :info
    WARNING = :warning
    CRITICAL = :critical
    CLIENT = :client
    DATABASE = :database 
    SYSTEM = :system
end

class Logger
  COLORS = {
    LogType::INFO => :blue,
    LogType::WARNING => :yellow,
    LogType::CRITICAL => :red,
    LogType::CLIENT => :magenta,
    LogType::DATABASE => :green,
    LogType::SYSTEM => :cyan,
  }

  class << self 
        def timestamp
          "[#{Time.now.strftime("%H:%M:%S")}]".gray
        end

        def divider
          ">>".gray
        end

        def notification(type, message)
          label = type.to_s.upcase.send(COLORS[type] || :white)

          puts "#{timestamp} | #{label} #{divider} #{message}"
        end

        def error(message, error = nil)
          label = "ERROR ".red

          puts "#{timestamp} | #{label} #{divider} #{message}"

          if error && error.backtrace
            puts error.backtrace.join("\n").gray
          end
        end
  end
end