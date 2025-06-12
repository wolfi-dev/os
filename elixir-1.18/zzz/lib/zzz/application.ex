defmodule Zzz.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # children = [
    #   # Starts a worker by calling: Zzz.Worker.start_link(arg)
    #   # {Zzz.Worker, arg}
    # ]
    children = [
      {Plug.Cowboy, scheme: :http, plug: Zzz.Router, options: [port: 8080]}
    ]

    IO.puts("Starting server on http://localhost:8080")
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Zzz.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
