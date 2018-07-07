defmodule Fcs.API do
  @moduledoc """
  This module provides a simple API for accessing Fcs search functionality
  """
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: :fcs_api)
  end

  @impl true
  def init(_) do
    {:ok, %{}}
  end


  @doc """
  Finds synchronously `request` in all files in `folder` directory
  and prints time and searching results
  """
  def bench(request, folder) do
    # IO.puts(:erlang.system_info(:logical_processors_available))
    # IO.puts(:erlang.system_info(:schedulers_online))
    # :erlang.system_flag(:logical_processors_available, 1)
    # IO.puts(:erlang.system_info(:logical_processors_available))
    {time, result} = :timer.tc(fn -> find(request, folder) end)
    IO.puts(time)
    IO.inspect(result)
  end

  @doc """
  Finds synchronously `request` in all files in current working directory
  """
  def find(request) when is_binary(request) do
    GenServer.call(:fcs_api, {:find, request}) # sync
  end

  @doc """
  Finds synchronously `request` in all files in `folder` directory
  """
  def find(request, folder) when is_binary(request) and is_binary(folder) do
    GenServer.call(:fcs_api, {:find, request, folder}, :infinity) # sync
  end

  def find(request, folder, opts) when is_binary(request) and is_binary(folder) and is_list(opts) do
    GenServer.call(:fcs_api, {:find, request, folder, opts}) # sync
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

  @impl true
  def handle_call({:find, request, folder, opts}, _from, state) do
    {:reply, Fcs.Searcher.find(request, folder, opts), state}
  end


end
