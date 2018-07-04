defmodule Fcs.API do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: :fcs_api)
  end

  @impl true
  def init(_) do
    {:ok, %{}}
  end

  def find(request) when is_binary(request) do
    GenServer.call(:fcs_api, {:find, request}) # sync
  end

  def find(request, folder) when is_binary(request) and is_binary(folder) do
    GenServer.call(:fcs_api, {:find, request, folder}) # sync
  end

  # Callbacks

  @impl true
  def handle_call({:find, request}, _from, state) do
    {:reply, Fcs.Searcher.find(request, "."), state}
  end

  @impl true
  def handle_call({:find, request, folder}, _from, state) do
    {:reply, Fcs.Searcher.find(request, folder), state}
  end
end
