require 'tcp_null/version'
require 'socket'

module TcpNull

  class Server

    attr_accessor :hostname, :port, :echo, :http, :verbose

    def initialize(hostname: 'localhost', port: 9999, verbose: false, echo: false, http: false)
      #logputs '[*] Initializing server.'
      @hostname = hostname
      @port = port
      @verbose = verbose
      @echo = echo
      @http = http
      if @http
        @echo = true
      end
      @server = TCPServer.new hostname, @port
    end

    def vputs(str)
      # Print to STDOUT only if verbose mode is true
      if @verbose
        puts str
      end
    end

    def start
      loop do  # Keep listening and serving threads
        Thread.start(@server.accept) do |client|
          _, _, remote_hostname, remote_ip = client.peeraddr
          vputs '[*] Received connection from ' + remote_hostname + '|' + remote_ip

          loop do  # Keep receiving and echoing until client disconnects.
            content = client.recv(65535)
            vputs '[*] Received ' + content.length.to_s + ' bytes from client ' + remote_hostname + '|' + remote_ip
            vputs content
            if @echo
              if @http
                client.write("HTTP/1.1 200 OK\nContent-Length: " + content.length.to_s +  "\n\n")
                client.write content
              else
                client.write content
              end
            end
          end

        end
      end
    end

    def stop
      @server.close
    end

  end

end
