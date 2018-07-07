defmodule Fcs.API.Supervisor do
  @moduledoc """
  API supervisor, runs Fcs.API worker
  """

  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  @impl true
  def init(_) do
    children = [
      worker(Fcs.API, [])
    ]

    supervise(children, strategy: :one_for_all)
  end
end
