require 'rubygems'
require 'em-proxy'

Proxy.start(:host => "0.0.0.0", :port => 8088, :debug => true) do |conn|
  conn.server :srv, :host => "127.0.0.1", :port => 8089

  # modify / process request stream
  conn.on_data do |data|
    p [:on_data, data]
    data
  end

  # modify / process response stream
  conn.on_response do |backend, resp|
    resp = resp.gsub("~x0x~", "\0")
    p [:on_response, backend, resp]
    resp
  end

  # termination logic
  conn.on_finish do |backend, name|
    p [:on_finish, name]

    # terminate connection (in duplex mode, you can terminate when prod is done)
    # unbind if backend == :srv
  end
end
