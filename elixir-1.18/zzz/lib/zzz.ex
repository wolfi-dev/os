defmodule Zzz.Router do
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
