defmodule RustSortedMap.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    map = RustSortedMap.new()
    IO.inspect(RustSortedMap.insert(map, "1", "2"))
    IO.inspect(RustSortedMap.get(map, "1"))

    children = [
      # Starts a worker by calling: RustSortedMap.Worker.start_link(arg)
      # {RustSortedMap.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: RustSortedMap.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
