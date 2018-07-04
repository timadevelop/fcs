defmodule Fcs do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Fcs.Supervisor.start_link
  end
end
