module Raibo
  class Connection
    attr_accessor :server, :port, :nick, :channel

    def initialize(server, opts={})
      @server  = server
      @port    = opts[:port]    || 6667
      @nick    = opts[:nick]    || 'Raibo'
      @channel = opts[:channel] || '#raibo'
      @verbose = !!opts[:verbose]
    end

    def open
      @connection = TCPSocket.new(@server, @port)
      send "USER #{@nick} 0 * :Hi"
      nick @nick

      handle_lines do |line|
        case line
        when /:Nickname is already in use/
          @nick = "#{@nick}_"
          nick @nick
        when /001/
          join @channel
          break
        end
      end
    end

    def close
      @connection.close if @connection
    end

    def handle_lines
      while (line = @connection.gets)
        puts "--> #{line}" if @verbose

        if line =~ /^PING (.*)/
          send "PONG #{$1}"
        else
          yield line
        end
      end
    end

    def nick(nick)
      send "NICK #{nick}"
    end

    def join(channel)
      send "JOIN #{channel}"
    end

    def part(channel)
      send "PART #{channel}"
    end

    def say(msg)
      msg(@channel, msg)
    end

    def msg(dest, msg)
      send "PRIVMSG #{dest} :#{msg}"
    end

    def send(str)
      puts "<-- #{str}" if @verbose
      @connection.puts(str)
    end
  end
end