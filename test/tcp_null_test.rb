require 'socket'
require File.expand_path("../test_helper", __FILE__)

# TODO Sometimes the tests fail without good reason. Port conflicts or something. Rerunning usually works.

class TcpNullTest < Minitest::Test

  def setup
    @port_number = Random::rand(10000..50000)
  end

  def test_server_starts_and_listens_on_default_host_and_port
    begin
      server = TcpNull::Server.new  # No parameters, default host/port
      Thread.new { server.start }  # Start server in background
    rescue
      flunk 'Error starting server.'
    end

    begin
      test_client = TCPSocket.new(server.hostname, server.port)
      test_client.close
    rescue
      flunk 'Client error connecting to server.'
    end

    server.stop
  end

  def test_server_starts_and_listens_on_custom_port
    begin
      server = TcpNull::Server.new hostname:'localhost', port: @port_number
      Thread.new { server.start }
    rescue
      flunk 'Error starting server.'
    end

    begin
      test_client = TCPSocket.new(server.hostname, server.port)
      test_client.close
    rescue
      flunk 'Client error connecting to server.'
    end

    server.stop
  end

  def test_server_starts_and_listens_on_custom_hostname
    self.skip(msg='Too difficult to test custom hostnames')
  end

  def test_server_echos_content_back_to_client_with_echo_mode_on
    begin
      server = TcpNull::Server.new hostname: 'localhost', port: @port_number, echo: true
      Thread.new { server.start }
    rescue
      flunk 'Error starting server.'
    end

    begin
      test_client = TCPSocket.new(server.hostname, server.port)
      test_client.write("Test Content\n123\n!@#\nTest")
      response = test_client.recv(65535)
      test_client.close
      if response != "Test Content\n123\n!@#\nTest"
        flunk 'Content does not match'
        puts response
      end
    rescue
      flunk 'Client error connecting to server.'
    end

    server.stop
  end

  def test_server_echos_nothing_back_to_client_with_echo_mode_off
    skip(msg='Will wait forever when trying to read back nothing.')
  end

  # Test verbose mode outputs the contents received to screen
  def test_verbose_mode_server_prints_received_contents_to_stdout
    skip(msg='Do not know how to capture STDOUT without implementing custom output stream variable')
  end

  def test_http_force_echo_option_true
      server = TcpNull::Server.new echo: false, http: true
      # Even though echo was set to false, HTTP setting overrides that, setting echo to true
      assert server.echo, true
  end

  def test_http_option_returns_proper_response
    begin
      server = TcpNull::Server.new hostname: 'localhost', port: @port_number, echo: true, http: true
      Thread.new { server.start }
    rescue
      flunk 'Error starting server.'
    end

    begin
      test_client = TCPSocket.new server.hostname, server.port
      test_client.puts('Test Content')
      response = test_client.recv(65535)
      test_client.close

      if response != "HTTP/1.1 200 OK\nContent-Length: 13\n\nTest Content\n"
        flunk 'Content does not match'
        puts response
      end
    rescue
      flunk 'Client error with server.'
    end

    server.stop
  end

end