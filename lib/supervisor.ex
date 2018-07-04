defmodule Fcs.Supervisor do
  @moduledoc false

  use Supervisor

  @impl true
  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  @impl true
  def init(_) do
    children = [
      supervisor(Fcs.API.Supervisor, [])
      #worker
    ]

    supervise(children, strategy: :one_for_all)
  end
end
