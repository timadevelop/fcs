defmodule Fcs.Supervisor do
  @moduledoc """
  Fcs Main Supervisor, runs API
  """

  use Supervisor

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
