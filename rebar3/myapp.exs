Mix.install([
  {:plug_cowboy, "~> 2.5"}
])

defmodule HelloWorld.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/" do
    send_resp(conn, 200, "Hello, Elixir!")
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end

port = 8080

IO.puts("Starting server on http://localhost:#{port}")
{:ok, _pid} = Plug.Cowboy.http(HelloWorld.Router, [], port: port)

Process.sleep(10)
